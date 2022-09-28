use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

type RefNode = RefCell<Node>;

/**
 * Your MyLinkedList object will be instantiated and called as such:
 * let obj = MyLinkedList::new();
 * let ret_1: i32 = obj.get(index);
 * obj.add_at_head(val);
 * obj.add_at_tail(val);
 * obj.add_at_index(index, val);
 * obj.delete_at_index(index);
 */
#[derive(Default)]
pub struct MyLinkedList {
    count: i32,
    head: Option<Rc<RefNode>>,
    tail: Option<Rc<RefNode>>,
}

struct Node {
    val: i32,
    prev: Option<Weak<RefNode>>,
    next: Option<Rc<RefNode>>,
}

impl Node {
    fn new(val: i32, prev: Option<Weak<RefNode>>, next: Option<Rc<RefNode>>) -> Self {
        Self { val, prev, next }
    }
}

/**
 * `&self` means the method takes an immutable reference.
 * If you need a mutable reference, change it to `&mut self` instead.
 */
impl MyLinkedList {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn get(&self, index: i32) -> i32 {
        if let Some(n) = self.get_node(index) {
            n.as_ref().borrow().val
        } else {
            -1
        }
    }

    pub fn add_at_head(&mut self, val: i32) {
        let n = Rc::new(RefCell::new(Node::new(val, None, self.head.clone())));
        if self.tail.is_none() {
            self.tail = Some(n.clone());
        }
        if let Some(head) = &self.head {
            head.as_ref().borrow_mut().prev = Some(Rc::downgrade(&n));
        }
        self.head = Some(n);
        self.count += 1;
    }

    pub fn add_at_tail(&mut self, val: i32) {
        if let Some(tail) = &self.tail {
            let n = Rc::new(RefCell::new(Node::new(
                val,
                Some(Rc::downgrade(tail)),
                None,
            )));
            tail.as_ref().borrow_mut().next = Some(n.clone());
            self.tail = Some(n);
            self.count += 1;
        } else {
            self.add_at_head(val);
        }
    }

    pub fn add_at_index(&mut self, index: i32, val: i32) {
        if index <= 0 {
            self.add_at_head(val);
        } else if index == self.count {
            self.add_at_tail(val);
        } else if index > self.count {
        } else {
            let before = self.get_node(index).unwrap();
            let prev = before.as_ref().borrow().prev.clone();
            let n = Rc::new(RefCell::new(Node::new(
                val,
                prev.clone(),
                Some(before.clone()),
            )));
            before.as_ref().borrow_mut().prev = Some(Rc::downgrade(&n));
            prev.as_ref()
                .unwrap()
                .upgrade()
                .unwrap()
                .as_ref()
                .borrow_mut()
                .next = Some(n);
            self.count += 1;
        }
    }

    pub fn delete_at_index(&mut self, index: i32) {
        if let Some(n) = self.get_node(index) {
            if let Some(head) = self.head.as_ref() {
                if Rc::ptr_eq(head, &n) {
                    self.head = n.as_ref().borrow().next.clone();
                }
            }
            if let Some(tail) = self.tail.as_ref() {
                if Rc::ptr_eq(tail, &n) {
                    self.tail = n
                        .as_ref()
                        .borrow()
                        .prev
                        .as_ref()
                        .map(|x| x.upgrade().unwrap());
                }
            }
            if let Some(next) = &n.as_ref().borrow().next {
                next.as_ref().borrow_mut().prev = n.as_ref().borrow().prev.clone();
            }
            if let Some(prev) = n
                .as_ref()
                .borrow()
                .prev
                .as_ref()
                .map(|x| x.upgrade().unwrap())
            {
                prev.as_ref().borrow_mut().next = n.as_ref().borrow().next.clone();
            }
            self.count -= 1
        }
    }

    fn get_node(&self, index: i32) -> Option<Rc<RefNode>> {
        if index >= self.count || index < 0 {
            return None;
        }
        let mut node = self.head.clone();
        for _ in 0..index {
            if let Some(n) = node {
                node = n.as_ref().borrow().next.clone();
            } else {
                break;
            }
        }
        node
    }
}

#[cfg(test)]
mod tests {
    use crate::MyLinkedList;

    #[test]
    fn it_works1() {
        let mut l = MyLinkedList::new(); //[]
        let v = l.get(0);
        assert_eq!(-1, v);
        l.add_at_head(1); //[1]
        l.add_at_tail(3); //[1,3]
        l.add_at_index(1, 2); //[1,2,3]
        let v = l.get(-1);
        assert_eq!(-1, v);
        let v = l.get(0);
        assert_eq!(1, v);
        let v = l.get(1);
        assert_eq!(2, v);
        let v = l.get(2);
        assert_eq!(3, v);
        let v = l.get(3);
        assert_eq!(-1, v);
        l.delete_at_index(1); //[1,3]
        let v = l.get(1);
        assert_eq!(3, v);
        let v = l.get(2);
        assert_eq!(-1, v);
        l.delete_at_index(0); //[3]
        let v = l.get(0);
        assert_eq!(3, v);
        l.delete_at_index(0); //[]
        let v = l.get(0);
        assert_eq!(-1, v);
        l.add_at_tail(3); //[3]
        let v = l.get(0);
        assert_eq!(3, v);
        l.add_at_index(1, 4); //[3,4]
        let v = l.get(0);
        assert_eq!(3, v);
        let v = l.get(1);
        assert_eq!(4, v);
    }

    #[test]
    fn it_works2() {
        let mut l = MyLinkedList::new(); //[]
        l.add_at_index(0, 10);
        l.add_at_index(0, 20);
        l.add_at_index(0, 30);
        let v = l.get(0);
        assert_eq!(30, v);
        let v = l.get(1);
        assert_eq!(20, v);
        let v = l.get(2);
        assert_eq!(10, v);
    }
}
