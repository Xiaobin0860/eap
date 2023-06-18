#[derive(Debug, PartialEq, Eq)]
pub enum Comparison {
    Equal,
    Sublist,
    Superlist,
    Unequal,
}

pub fn sublist<T: PartialEq>(first_list: &[T], second_list: &[T]) -> Comparison {
    if first_list.len() == second_list.len() {
        if first_list == second_list {
            Comparison::Equal
        } else {
            Comparison::Unequal
        }
    } else if first_list.len() < second_list.len() {
        if first_list.is_empty() {
            Comparison::Sublist
        } else if second_list
            .windows(first_list.len())
            .any(|w| w == first_list)
        {
            Comparison::Sublist
        } else {
            Comparison::Unequal
        }
    } else {
        if second_list.is_empty() {
            Comparison::Superlist
        } else if first_list
            .windows(second_list.len())
            .any(|w| w == second_list)
        {
            Comparison::Superlist
        } else {
            Comparison::Unequal
        }
    }
}
