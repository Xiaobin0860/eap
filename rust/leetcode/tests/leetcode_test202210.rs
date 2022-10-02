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

#[cfg(test)]
mod tests {
    use crate::check_ones_segment;

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
}