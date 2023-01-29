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

    ListNode* head() const
    {
        return _head;
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

TEST(List, list)
{
    List l;
    l.push(1);
    ASSERT_TRUE(l.head());
    l.push(2);
    l.push(3);
    ASSERT_TRUE(l.head());
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
