use std::{collections::HashMap, thread};

pub fn frequency(input: &[&str], worker_count: usize) -> HashMap<char, usize> {
    let mut result = HashMap::new();
    thread::scope(|scope| {
        let handles = input
            .chunks(input.len() / worker_count + 1)
            .map(|chunk| scope.spawn(|| frequency_single_thread(chunk)));
        for handle in handles {
            let m = handle.join().unwrap();
            m.iter().for_each(|(k, v)| {
                *result.entry(*k).or_insert(0) += v;
            });
        }
    });
    result
}

fn frequency_single_thread(input: &[&str]) -> HashMap<char, usize> {
    input
        .iter()
        .flat_map(|&s| s.chars())
        .map(|c| c.to_ascii_lowercase())
        .filter(|c| c.is_alphabetic())
        .fold(HashMap::new(), |mut acc, c| {
            *acc.entry(c).or_insert(0) += 1;
            acc
        })
}
