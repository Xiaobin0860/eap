/// # 检查二进制字符串字段
///
/// 给你一个二进制字符串 s ，该字符串 不含前导零 。
/// 如果 s 包含 零个或一个由连续的 '1' 组成的字段 ，返回 true​​​ 。否则，返回 false 。
/// 如果 s 中 由连续若干个 '1' 组成的字段 数量不超过 1，返回 true​​​ 。否则，返回 false 。
///
/// ## 示例 1：
///
/// ```
/// 输入：s = "1001"
/// 输出：false
/// 解释：由连续若干个 '1' 组成的字段数量为 2，返回 false
/// ```
///
/// ## 示例 2：
///
/// ```
/// 输入：s = "110"
/// 输出：true
/// ```
///
/// ## 提示：
///
/// ```
/// 1 <= s.length <= 100
/// s[i]​​​​ 为 '0' 或 '1'
/// s[0] 为 '1'
/// ```
fn check_ones_segment(s: String) -> bool {
    let ss = s.as_str();
    if let Some(zidx) = ss.find('0') {
        let sub = &ss[zidx..];
        if sub.contains('1') {
            return false;
        }
    }
    true
}

/// # 使括号有效的最少添加
///
/// 只有满足下面几点之一，括号字符串才是有效的：
///
///    它是一个空字符串，或者
///    它可以被写成 AB （A 与 B 连接）, 其中 A 和 B 都是有效字符串，或者
///    它可以被写作 (A)，其中 A 是有效字符串。
///
/// 给定一个括号字符串 s ，移动N次，你就可以在字符串的任何位置插入一个括号。
///
///    例如，如果 s = "()))" ，你可以插入一个开始括号为 "(()))" 或结束括号为 "())))" 。
///
/// 返回 为使结果字符串 s 有效而必须添加的最少括号数。
///
/// ## 示例 1：
///
/// ```
/// 输入：s = "())"
/// 输出：1
/// ```
///
/// ## 示例 2：
///
/// ```
/// 输入：s = "((("
/// 输出：3
/// ```
///
/// ## 提示：
///
/// ```
/// 1 <= s.length <= 1000
/// s 只包含 '(' 和 ')' 字符。
/// ```
fn min_add_to_make_valid(s: String) -> i32 {
    let mut left = 0;
    let mut right = 0;
    for c in s.as_str().chars() {
        match c {
            '(' => left += 1,
            ')' => {
                if left > 0 {
                    left -= 1;
                } else {
                    right += 1;
                }
            }
            _ => panic!("invalid"),
        }
    }
    left + right
}

/// https://leetcode.cn/problems/sign-of-the-product-of-an-array/
fn array_sign(nums: Vec<i32>) -> i32 {
    let mut sign = 1;
    for n in nums {
        match n {
            0 => return 0,
            n if n < 0 => sign *= -1,
            _ => {}
        };
    }
    sign
}

/// https://leetcode.cn/problems/shortest-subarray-with-sum-at-least-k/
fn shortest_subarray(nums: Vec<i32>, k: i32) -> i32 {
    use std::collections::VecDeque;
    let (mut ret, mut pre_sum, mut queue) = (i64::MAX, 0, VecDeque::new());
    queue.push_back((0, -1));
    for (i, num) in nums.iter().enumerate() {
        pre_sum += num;
        while !queue.is_empty() && pre_sum <= queue[queue.len() - 1].0 {
            queue.pop_back();
        }
        while !queue.is_empty() && pre_sum - queue[0].0 >= k {
            ret = ret.min(i as i64 - queue.pop_front().unwrap().1 as i64);
        }
        queue.push_back((pre_sum, i as i32));
    }
    if ret == i64::MAX {
        -1
    } else {
        ret as i32
    }
}

#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn test_check_ones_segment() {
        assert!(!check_ones_segment("1001".into()));
        assert!(check_ones_segment("110".into()));
        assert!(check_ones_segment("1".into()));
        assert!(check_ones_segment("11".into()));
        assert!(check_ones_segment("10".into()));
        assert!(!check_ones_segment("101".into()));
        assert!(!check_ones_segment("10101".into()));
    }

    #[test]
    fn test_min_add_to_make_valid() {
        assert_eq!(1, min_add_to_make_valid("())".into()));
        assert_eq!(2, min_add_to_make_valid("()()))".into()));
        assert_eq!(3, min_add_to_make_valid("(((".into()));
        assert_eq!(0, min_add_to_make_valid("()(())".into()));
        assert_eq!(0, min_add_to_make_valid("".into()));
        assert_eq!(3, min_add_to_make_valid(")()))".into()));
    }

    #[test]
    fn test_array_sign() {
        assert_eq!(1, array_sign(vec!(-1, -2, -3, -4, 3, 2, 1)));
        assert_eq!(0, array_sign(vec!(1, 5, 0, 2, -3)));
        assert_eq!(-1, array_sign(vec!(-1, 1, -1, 1, -1)));
    }

    #[test]
    fn test_shortest_subarray() {
        assert_eq!(1, shortest_subarray(vec!(1), 1));
        assert_eq!(-1, shortest_subarray(vec!(1, 2), 4));
        assert_eq!(3, shortest_subarray(vec!(2, -1, 2), 3));
        assert_eq!(1, shortest_subarray(vec!(1, 2, 3, 4, 1, 9, 10), 10));
        assert_eq!(
            48,
            shortest_subarray(
                vec!(
                    58701, 23101, 6562, 60667, 20458, -14545, 74421, 54590, 84780, 63295, 33238,
                    -10143, -35830, -9881, 67268, 90746, 9220, -15611, 23957, 29506, -33103,
                    -14322, 19079, -34950, -38551, 51786, -48668, -17133, 5163, 15122, 5463, 74527,
                    41111, -3281, 73035, -28736, 32910, 17414, 4080, -42435, 66106, 48271, 69638,
                    14500, 37084, -9978, 85748, -43017, 75337, -27963, -34333, -25360, 82454,
                    87290, 87019, 84272, 17540, 60178, 51154, 19646, 54249, -3863, 38665, 13101,
                    59494, 37172, -16950, -30560, -11334, 27620, 73388, 34019, -35695, 98999,
                    79086, -28003, 87339, 2448, 66248, 81817, 73620, 28714, -46807, 51901, -23618,
                    -29498, 35427, 11159, 59803, 95266, 20307, -3756, 67993, -31414, 11468, -28307,
                    45126, 77892, 77226, 79433
                ),
                1677903
            )
        );
    }
}
