pub mod anagram;
pub mod clock;
pub mod gigasecond;
pub mod minesweeper;
pub mod reverse_string;
pub mod space_age;
pub mod sublist;

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
