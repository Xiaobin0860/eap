// Definition for singly-linked list.
#[derive(PartialEq, Eq, Clone, Debug)]
struct ListNode {
    pub val: i32,
    pub next: Option<Box<ListNode>>,
}
#[allow(dead_code)]
impl ListNode {
    #[inline]
    fn new(val: i32) -> Self {
        ListNode { next: None, val }
    }
}

#[derive(Debug)]
struct List {
    head: Option<Box<ListNode>>,
}

impl List {
    fn new() -> Self {
        Self { head: None }
    }

    fn push(&mut self, val: i32) {
        let node = Box::new(ListNode {
            next: self.head.take(),
            val,
        });
        self.head = Some(node);
    }

    fn pop(&mut self) -> Option<i32> {
        match self.head.take() {
            Some(node) => {
                self.head = node.next;
                Some(node.val)
            }
            None => None,
        }
    }

    fn reverse(&mut self) {
        let mut cur_head = self.head.take();
        while let Some(mut cur_node) = cur_head {
            let cur_next = cur_node.next.take();
            cur_node.next = self.head.take();
            self.head = Some(cur_node);
            cur_head = cur_next
        }
    }
}

impl From<List> for Vec<i32> {
    fn from(mut l: List) -> Self {
        let mut v = Vec::new();
        let mut cur_head = l.head.take();
        while let Some(mut n) = cur_head {
            v.push(n.val);
            cur_head = n.next.take();
        }
        v
    }
}

impl From<Vec<i32>> for List {
    fn from(v: Vec<i32>) -> Self {
        let mut l = List::new();
        for i in v.into_iter().rev() {
            l.push(i);
        }
        l
    }
}

fn reverse_list(head: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
    let mut list = List { head };
    list.reverse();
    list.head
}

#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn test_list() {
        let mut list = List::new();
        assert!(list.head.is_none());
        list.push(1);
        assert!(list.head.is_some());
        list.push(2);
        list.push(3);
        list.push(4);
        list.push(5);
        assert!(list.head.is_some());
        assert_eq!(list.pop(), Some(5));
        assert_eq!(list.pop(), Some(4));
        assert_eq!(list.pop(), Some(3));
        assert_eq!(list.pop(), Some(2));
        assert_eq!(list.pop(), Some(1));
        assert_eq!(list.pop(), None);
        assert_eq!(list.pop(), None);
        assert!(list.head.is_none());

        list.push(5);
        list.push(4);
        list.push(3);
        list.push(2);
        list.push(1);
        let v: Vec<_> = list.into();
        assert_eq!(v, vec![1, 2, 3, 4, 5]);
        list = v.clone().into();
        assert!(list.head.is_some());
        let v2: Vec<_> = list.into();
        assert_eq!(v, v2);
        list = v.clone().into();
        list.reverse();
        let v3: Vec<_> = list.into();
        assert_eq!(v3, vec![5, 4, 3, 2, 1]);
    }

    #[test]
    fn test_reverse_list() {
        let v = vec![1, 2, 3, 4, 5];
        let l: List = v.clone().into();
        let head = reverse_list(l.head);
        let l = List { head };
        let rv: Vec<_> = l.into();
        assert_eq!(rv, vec![5, 4, 3, 2, 1])
    }
}
