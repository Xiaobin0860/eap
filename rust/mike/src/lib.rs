pub fn add(left: usize, right: usize) -> usize {
    left + right
}

mod token_output_stream;
pub use token_output_stream::*;

mod yolo_model;
pub use yolo_model::*;

mod coco_classes;
pub use coco_classes::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
