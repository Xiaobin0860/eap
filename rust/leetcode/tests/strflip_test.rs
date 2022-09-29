/**
字符串轮转。给定两个字符串s1和s2，请编写代码检查s2是否为s1旋转而成（比如，waterbottle是erbottlewat旋转后的字符串）。

示例1:

 输入：s1 = "waterbottle", s2 = "erbottlewat"
 输出：True

示例2:

 输入：s1 = "aa", s2 = "aba"
 输出：False

提示：

    字符串长度在[0, 100000]范围内。

说明:

    你能只调用一次检查子串的方法吗？
 */

fn is_fliped_string(s1: String, s2: String) -> bool {
    if s1.len() != s2.len() {
        return false;
    }
    // let r1 = s1.as_str();
    // let r2 = s2.as_str();
    // let s = format!("{r1}{r1}");
    // s.contains(r2)
    let s = s1.to_owned() + &s1;
    s.contains(&s2)
}

#[cfg(test)]
mod tests {
    use crate::is_fliped_string;

    #[test]
    fn it_split() {
        let vs: Vec<_> = "waterwater".split("water").collect();
        assert_eq!(vec!["", "", ""], vs);
        let vs: Vec<_> = "waterwater".split("aater").collect();
        assert_eq!(vec!["waterwater"], vs);
        let vs: Vec<_> = "water".split("water").collect();
        assert_eq!(vec!["", ""], vs);
    }

    #[test]
    fn it_works() {
        assert!(is_fliped_string("waterbottle".into(), "erbottlewat".into()));
        assert!(is_fliped_string("waterbottle".into(), "waterbottle".into()));
        assert!(!is_fliped_string("aa".into(), "aba".into()));
        assert!(!is_fliped_string("aa".into(), "ba".into()));
        assert!(!is_fliped_string("aa".into(), "ab".into()));
    }
}
