#include <gtest/gtest.h>

/**
 * Definition for singly-linked list.
 */
struct ListNode {
    int       val;
    ListNode* next;
    ListNode()
        : val(0)
        , next(nullptr)
    {
    }
    ListNode(int x)
        : val(x)
        , next(nullptr)
    {
    }
    ListNode(int x, ListNode* next)
        : val(x)
        , next(next)
    {
    }
};

class List {
public:
    List()
    {
    }
    List(ListNode* head)
        : _head(head)
    {
    }

    ~List()
    {
        while (auto node = _head) {
            _head = node->next;
            delete node;
        }
        assert(_head == nullptr);
    }

    ListNode* get_head() const
    {
        return _head;
    }

    void set_head(ListNode* head)
    {
        _head = head;
    }

    void push(int val)
    {
        auto node = new ListNode(val, _head);
        _head = node;
    }

    std::pair<bool, int> pop()
    {
        if (!_head) {
            return {false, 0};
        }
        auto node = _head;
        _head = _head->next;
        auto val = node->val;
        delete node;
        return {true, val};
    }

    void reverse()
    {
        auto cur_head = _head;
        _head = nullptr;
        while (auto cur_node = cur_head) {
            auto cur_next = cur_node->next;
            cur_node->next = _head;
            _head = cur_node;
            cur_head = cur_next;
        }
    }

private:
    ListNode* _head = nullptr;
};

namespace {
bool has_cycle(ListNode* head)
{
    if (!head || !head->next) {
        return false;
    }
    auto slow = head;
    auto fast = head->next;
    while (slow != fast) {
        if (!fast || !fast->next) {
            return false;
        }
        slow = slow->next;
        fast = fast->next->next;
    }
    return true;
}
ListNode* merge_lists(ListNode* list1, ListNode* list2)
{
    ListNode* result = nullptr;
    ListNode* head = nullptr;
    auto      next = [&result, &head](auto& node) {
        if (head) {
            head->next = node;
            head = node;
        } else {
            head = node;
            if (!result) {
                result = head;
            }
        }
        node = node->next;
    };
    while (list1 && list2) {
        if (list2->val < list1->val) {
            next(list2);
        } else {
            next(list1);
        }
    }
    if (list1) {
        if (head) {
            head->next = list1;
        } else {
            result = list1;
        }
    } else if (list2) {
        if (head) {
            head->next = list2;
        } else {
            result = list2;
        }
    }
    return result;
}
ListNode* merge_lists2(ListNode* list1, ListNode* list2)
{
    if (!list1) {
        return list2;
    } else if (!list2) {
        return list1;
    } else if (list2->val < list1->val) {
        auto list = list2;
        list->next = merge_lists2(list1, list2->next);
        return list;
    } else {
        auto list = list1;
        list->next = merge_lists2(list1->next, list2);
        return list;
    }
}
}  // namespace

TEST(List, list)
{
    // common op & reverse
    {
        List l;
        l.push(1);
        ASSERT_TRUE(l.get_head());
        l.push(2);
        l.push(3);
        ASSERT_TRUE(l.get_head());
        ASSERT_EQ(std::make_pair(true, 3), l.pop());
        ASSERT_EQ(std::make_pair(true, 2), l.pop());
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(false, 0), l.pop());

        l.push(1);
        l.push(2);
        l.push(3);
        l.reverse();
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(true, 2), l.pop());
        ASSERT_EQ(std::make_pair(true, 3), l.pop());
        ASSERT_EQ(std::make_pair(false, 0), l.pop());
    }
    // merge
    {
        //[1,2,4]
        List l1;
        l1.push(4);
        l1.push(2);
        l1.push(1);
        //[1,3,4]
        List l2;
        l2.push(4);
        l2.push(3);
        l2.push(1);
        auto head = merge_lists(l1.get_head(), l2.get_head());
        l1.set_head(nullptr);
        l2.set_head(nullptr);
        //[1,1,2,3,4,4]
        List l(head);
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(true, 2), l.pop());
        ASSERT_EQ(std::make_pair(true, 3), l.pop());
        ASSERT_EQ(std::make_pair(true, 4), l.pop());
        ASSERT_EQ(std::make_pair(true, 4), l.pop());
        ASSERT_EQ(std::make_pair(false, 0), l.pop());
    }
    {
        //[1,2,4]
        List l1;
        l1.push(4);
        l1.push(2);
        l1.push(1);
        //[1,3,4]
        List l2;
        l2.push(4);
        l2.push(3);
        l2.push(1);
        auto head = merge_lists2(l1.get_head(), l2.get_head());
        l1.set_head(nullptr);
        l2.set_head(nullptr);
        //[1,1,2,3,4,4]
        List l(head);
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(true, 1), l.pop());
        ASSERT_EQ(std::make_pair(true, 2), l.pop());
        ASSERT_EQ(std::make_pair(true, 3), l.pop());
        ASSERT_EQ(std::make_pair(true, 4), l.pop());
        ASSERT_EQ(std::make_pair(true, 4), l.pop());
        ASSERT_EQ(std::make_pair(false, 0), l.pop());
    }
}
