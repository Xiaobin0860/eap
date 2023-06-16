use std::collections::HashSet;

pub fn anagrams_for<'a>(word: &str, possible_anagrams: &'a [&str]) -> HashSet<&'a str> {
    // let mut result = HashSet::new();
    // let word = word.to_lowercase();
    // for possible_anagram in possible_anagrams {
    //     let s = possible_anagram.to_lowercase();
    //     if word == s {
    //         continue;
    //     }
    //     let mut sv = s.chars().collect::<Vec<_>>();
    //     sv.sort_unstable();
    //     let mut wv = word.chars().collect::<Vec<_>>();
    //     wv.sort_unstable();
    //     if sv == wv {
    //         result.insert(*possible_anagram);
    //     }
    // }
    // result
    let word = word.to_lowercase();
    let mut wv = word.chars().collect::<Vec<_>>();
    wv.sort_unstable();
    possible_anagrams
        .iter()
        .filter(|s| {
            let s = s.to_lowercase();
            if s != word {
                let mut sv = s.chars().collect::<Vec<_>>();
                sv.sort_unstable();
                wv == sv
            } else {
                false
            }
        })
        .cloned()
        .collect()
}
