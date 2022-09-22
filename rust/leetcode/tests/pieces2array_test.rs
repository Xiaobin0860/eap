/// 给你一个整数数组`arr`，数组中的每个整数`互不相同`。另有一个由整数数组构成的数组`pieces`，其中的整数也`互不相同`。
/// 请你以`任意顺序`连接`pieces`中的数组以形成`arr`。但是，不允许 对每个数组`pieces[i]`中的整数重新排序。
/// 如果可以连接 pieces 中的数组形成 arr ，返回 true ；否则，返回 false 。
///
/// ## 示例 1：
/// ```
///     输入：arr = [15,88], pieces = [[88],[15]]
///     输出：true
///     解释：依次连接 [15] 和 [88]
/// ```
/// ## 示例 2：
/// ```
///     输入：arr = [49,18,16], pieces = [[16,18,49]]
///     输出：false
///     解释：即便数字相符，也不能重新排列 pieces[0]
/// ```
/// ## 示例 3：
/// ```
///     输入：arr = [91,4,64,78], pieces = [[78],[4,64],[91]]
///     输出：true
///     解释：依次连接 [91]、[4,64] 和 [78]
/// ```
///
use std::collections::HashMap;

fn can_form_array(arr: Vec<i32>, pieces: Vec<Vec<i32>>) -> bool {
    let mut map = HashMap::new();
    for (i, piece) in pieces.iter().enumerate() {
        map.insert(piece[0], i);
    }
    let mut i: usize = 0;
    while i < arr.len() {
        let m = arr[i];
        if let Some(idx) = map.get(&m) {
            let piece = &pieces[*idx];
            i += 1;
            for n in piece.iter().skip(1) {
                if i >= arr.len() || arr[i] != *n {
                    return false;
                }
                i += 1;
            }
        } else {
            return false;
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use crate::can_form_array;

    #[test]
    fn it_works() {
        let arr = vec![15, 88];
        let pieces = vec![vec![88], vec![15]];
        assert!(can_form_array(arr, pieces));

        let arr = vec![49, 18, 16];
        let pieces = vec![vec![16, 18, 49]];
        assert!(!can_form_array(arr, pieces));

        let arr = vec![91, 4, 64, 78];
        let pieces = vec![vec![78], vec![4, 64], vec![91]];
        assert!(can_form_array(arr, pieces));
    }
}
