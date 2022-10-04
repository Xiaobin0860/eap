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
}
