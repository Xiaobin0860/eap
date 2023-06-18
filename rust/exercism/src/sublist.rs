#[derive(Debug, PartialEq, Eq)]
pub enum Comparison {
    Equal,
    Sublist,
    Superlist,
    Unequal,
}

pub fn sublist<T: PartialEq>(first_list: &[T], second_list: &[T]) -> Comparison {
    match first_list.len().cmp(&second_list.len()) {
        std::cmp::Ordering::Equal => {
            if first_list == second_list {
                Comparison::Equal
            } else {
                Comparison::Unequal
            }
        }
        std::cmp::Ordering::Less => {
            if first_list.is_empty()
                || second_list
                    .windows(first_list.len())
                    .any(|w| w == first_list)
            {
                Comparison::Sublist
            } else {
                Comparison::Unequal
            }
        }
        std::cmp::Ordering::Greater => {
            if second_list.is_empty()
                || first_list
                    .windows(second_list.len())
                    .any(|w| w == second_list)
            {
                Comparison::Superlist
            } else {
                Comparison::Unequal
            }
        }
    }
}
