use std::collections::HashMap;

/// Given a list of poker hands, return a list of those hands which win.
///
/// Note the type signature: this function should return _the same_ reference to
/// the winning hand(s) as were passed in, not reconstructed strings which happen to be equal.
pub fn winning_hands<'a>(hands: &[&'a str]) -> Vec<&'a str> {
    let mut hands: Vec<(PockerHand, &'a str)> = hands.iter().map(|&h| (h.into(), h)).collect();
    hands.sort_unstable_by(|(a, _), (b, _)| b.cmp(a));
    let mut result = Vec::new();
    result.push(hands[0].1);
    for (h, s) in hands[1..].iter() {
        if h == &hands[0].0 {
            result.push(s);
        } else {
            break;
        }
    }
    result
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum CardRank {
    HighCard,      //"3S 4S 5D 6H JH"
    OnePair,       //"2S 4H 6C 4D JD"
    TwoPairs,      //"2S 8H 2D 8D 3H"
    ThreeOfAKind,  //"4S 5H 4C 8S 4H"
    Straight,      //"10D JH QS KD AC"
    Flush,         //"2S 4S 5S 6S 7S"
    FullHouse,     //"4S 5C 4C 5D 4H"
    FourOfAKind,   //"4S 5H 5S 5D 5C"
    StraightFlush, //"5S 7S 8S 9S 6S"
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct PockerHand {
    pub card_rank: CardRank,
    pub values: Vec<u8>,
}

impl From<&str> for PockerHand {
    fn from(card: &str) -> Self {
        //　parse　to values and suits
        let (values, suits): (Vec<_>, Vec<_>) = card
            .split_whitespace()
            .map(|s| {
                let (value, suit) = s.split_at(s.len() - 1);
                let value: u8 = match value.parse() {
                    Ok(v) => v,
                    Err(_) => "JQKA".find(value).unwrap() as u8 + 11,
                };
                let suit = suit.chars().next().unwrap() as u8;
                (value, suit)
            })
            .unzip();
        // 统计相同的value的个数
        let mut groups = HashMap::new();
        for v in values.iter() {
            *groups.entry(v).or_insert(0) += 1;
        }
        // 按照value的个数排序
        let mut groups: Vec<_> = groups.into_iter().map(|(k, v)| (v, k)).collect();
        groups.sort_unstable_by(|a, b| b.cmp(a));
        let (counts, values): (Vec<_>, Vec<_>) = groups.into_iter().unzip();
        match counts[0] {
            2 => {
                if counts[1] == 2 {
                    PockerHand {
                        card_rank: CardRank::TwoPairs,
                        values,
                    }
                } else {
                    PockerHand {
                        card_rank: CardRank::OnePair,
                        values,
                    }
                }
            }
            3 => {
                if counts[1] == 2 {
                    PockerHand {
                        card_rank: CardRank::FullHouse,
                        values,
                    }
                } else {
                    PockerHand {
                        card_rank: CardRank::ThreeOfAKind,
                        values,
                    }
                }
            }
            4 => PockerHand {
                card_rank: CardRank::FourOfAKind,
                values,
            },
            _ => {
                //从大到小排序
                let mut values = values;
                if values == [14, 5, 4, 3, 2] {
                    values = vec![5, 4, 3, 2, 1];
                }
                let is_straight = values[0] - values[4] == 4;
                let is_flush = suits[1..].iter().all(|&s| s == suits[0]);
                match (is_straight, is_flush) {
                    (true, true) => PockerHand {
                        card_rank: CardRank::StraightFlush,
                        values,
                    },
                    (true, false) => PockerHand {
                        card_rank: CardRank::Straight,
                        values,
                    },
                    (false, true) => PockerHand {
                        card_rank: CardRank::Flush,
                        values,
                    },
                    (false, false) => PockerHand {
                        card_rank: CardRank::HighCard,
                        values,
                    },
                }
            }
        }
    }
}
