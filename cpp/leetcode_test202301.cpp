#include <gtest/gtest.h>
#include "singleton.h"

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

    //单链表反转 206
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

    int get_length()
    {
        auto len = 0;
        auto cur_head = _head;
        while (auto node = cur_head) {
            cur_head = node->next;
            ++len;
        }
        return len;
    }

    // 删除链表倒数第n个结点 19
    bool remove_nth_from_end(int n)
    {
        if (n <= 0) {
            return false;
        }
        auto len = get_length();
        auto pre_idx = len - n;
        if (pre_idx < 0) {
            return false;
        }
        auto gard = new ListNode(0, _head);
        auto idx = 0;
        auto pre_node = gard;
        for (int i = 0; i < pre_idx; i++) {
            pre_node = pre_node->next;
        }
        auto del_node = pre_node->next;
        pre_node->next = del_node->next;
        delete del_node;
        _head = gard->next;
        delete gard;
        return true;
    }
    bool remove_nth_from_end2(int n)
    {
        if (n <= 0) {
            return false;
        }
        auto      gard = new ListNode(0, _head);
        ListNode* p1 = nullptr;
        ListNode* p2 = nullptr;
        auto      cur_head = gard;
        int       i = 0;
        while (p2 = cur_head) {
            cur_head = p2->next;
            if (i != n) {
                ++i;
            } else {
                if (p1) {
                    p1 = p1->next;
                } else {
                    p1 = gard;
                }
            }
        }
        if (!p1) {
            delete gard;
            return false;
        }
        auto del_node = p1->next;
        p1->next = del_node->next;
        delete del_node;
        _head = gard->next;
        delete gard;
        return true;
    }

    //求链表的中间结点 876
    ListNode* middle()
    {
        auto slow = _head;
        auto fast = _head;
        while (fast && fast->next) {
            slow = slow->next;
            fast = fast->next->next;
        }
        return slow;
    }

private:
    ListNode* _head = nullptr;
};

namespace {
//链表中环的检测 141
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
// 两个有序的链表合并 21
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
        ASSERT_EQ(1, l.get_length());
        l.push(2);
        l.push(3);
        ASSERT_EQ(3, l.get_length());
        ASSERT_EQ(2, l.middle()->val);
        ASSERT_TRUE(l.get_head());
        ASSERT_EQ(std::make_pair(true, 3), l.pop());
        ASSERT_EQ(2, l.get_length());
        //[2,1]
        ASSERT_EQ(1, l.middle()->val);
        l.remove_nth_from_end(2);
        //[1]
        ASSERT_EQ(1, l.middle()->val);
        l.remove_nth_from_end2(1);
        ASSERT_EQ(std::make_pair(false, 0), l.pop());
        ASSERT_EQ(0, l.get_length());

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

namespace {
//删除有序数组中的重复项 26
int remove_duplicates(std::vector<int>& nums)
{
    auto len = nums.size();
    auto slow = 1;
    for (auto fast = 1; fast < len; ++fast) {
        if (nums[fast] != nums[fast - 1]) {
            nums[slow++] = nums[fast];
        }
    }
    return slow;
}
}  // namespace

TEST(Array, array)
{
    // remove_duplicates
    {
        std::vector<int> v{1};

        auto n = remove_duplicates(v);
        ASSERT_EQ(1, n);
        ASSERT_EQ(1, v[0]);
        v.push_back(1);
        n = remove_duplicates(v);
        ASSERT_EQ(1, n);
        ASSERT_EQ(1, v[0]);
        ASSERT_EQ(2, v.size());
        ASSERT_EQ(1, v[1]);
        v.push_back(2);
        n = remove_duplicates(v);
        ASSERT_EQ(2, n);
        ASSERT_EQ(1, v[0]);
        ASSERT_EQ(2, v[1]);
        ASSERT_EQ(3, v.size());
        ASSERT_EQ(2, v[2]);
        v.push_back(3);
        v.push_back(3);
        n = remove_duplicates(v);
        ASSERT_EQ(3, n);
        ASSERT_EQ(1, v[0]);
        ASSERT_EQ(2, v[1]);
        ASSERT_EQ(3, v[2]);
    }
}

TEST(Singleton1, test)
{
    ASSERT_EQ(1, GetSingleton().GetCount());
    ASSERT_EQ(1, GetSingleton().GetCount());
}

TEST(Singleton1, test2)
{
    ASSERT_EQ(1, GetSingleton().GetCount());
    ASSERT_EQ(1, GetSingleton().GetCount());
}
