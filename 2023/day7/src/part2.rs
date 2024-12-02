use anyhow::{anyhow, Context, Result};
use std::str::FromStr;

#[derive(Debug, Copy, Clone)]
enum Card {
    A,
    K,
    Q,
    J,
    Num(u8),
}

impl PartialEq for Card {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Num(l0), Self::Num(r0)) => l0 == r0,
            _ => core::mem::discriminant(self) == core::mem::discriminant(other),
        }
    }
}

impl Eq for Card {}

impl PartialOrd for Card {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        let (da, db) = (
            core::mem::discriminant(self),
            core::mem::discriminant(other),
        );
        return match (self, other) {
            (Card::J, Card::J) => Some(std::cmp::Ordering::Equal),
            (Card::J, _) => Some(std::cmp::Ordering::Less),
            (_, Card::J) => Some(std::cmp::Ordering::Greater),
            (Self::Num(l0), Self::Num(r0)) => l0.partial_cmp(r0),
            _ if da == db => Some(std::cmp::Ordering::Equal),
            (Card::A, _) => Some(std::cmp::Ordering::Greater),
            (_, Card::A) => Some(std::cmp::Ordering::Less),
            (Card::K, _) => Some(std::cmp::Ordering::Greater),
            (_, Card::K) => Some(std::cmp::Ordering::Less),
            (Card::Q, _) => Some(std::cmp::Ordering::Greater),
            (_, Card::Q) => Some(std::cmp::Ordering::Less),
        };
    }
}

impl Ord for Card {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        return self.partial_cmp(other).unwrap();
    }
}

#[derive(Debug, Copy, Clone)]
enum HandDiscriminant {
    FiveOfAKind,
    FourOfAKind,
    FullHouse,
    ThreeOfAKind,
    TwoPairs,
    OnePair,
    HighCard,
}

impl PartialEq for HandDiscriminant {
    fn eq(&self, other: &Self) -> bool {
        return core::mem::discriminant(self) == core::mem::discriminant(other);
    }
}

impl Eq for HandDiscriminant {}

impl PartialOrd for HandDiscriminant {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        let (va, vb) = (*self as usize, *other as usize);
        return va.partial_cmp(&vb);
    }
}

#[derive(Debug, Clone, Copy)]
struct Hand {
    cards: [Card; 5],
    kind: HandDiscriminant,
    bid: u32,
}

impl PartialEq for Hand {
    fn eq(&self, other: &Self) -> bool {
        return self
            .cards
            .iter()
            .zip(other.cards.iter())
            .all(|(l, r)| l == r);
    }
}

impl Eq for Hand {}

impl PartialOrd for Hand {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        let (da, db) = (&self.kind, &other.kind);
        match da.partial_cmp(&db) {
            Some(std::cmp::Ordering::Equal) => {
                for (s, o) in self.cards.iter().zip(other.cards.iter()) {
                    match o.cmp(s) {
                        std::cmp::Ordering::Equal => continue,
                        ord => return Some(ord),
                    }
                }
                unreachable!("Hands are equal");
            }
            Some(ord) => return Some(ord),
            None => return None,
        }
    }
}

impl Ord for Hand {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        return self.partial_cmp(other).unwrap();
    }
}

fn parse_hand(cards: [Card; 5]) -> HandDiscriminant {
    let mut kind = HandDiscriminant::HighCard;

    let all_same = cards.iter().all(|c| c == &cards[0]);
    if all_same {
        kind = HandDiscriminant::FiveOfAKind;
        return kind;
    }
    let num_jokers = cards.iter().filter(|x| x == &&Card::J).count();
    if num_jokers == 4 {
        kind = HandDiscriminant::FiveOfAKind;
        return kind;
    }
    let cards = cards
        .iter()
        .filter(|x| x != &&Card::J)
        .copied()
        .collect::<Vec<_>>();
    let mut counts = [0; 5];
    for (i, c) in cards.iter().enumerate() {
        counts[i] = cards.iter().filter(|x| x == &c).count();
    }
    if counts.contains(&4) {
        kind = HandDiscriminant::FourOfAKind;
        if num_jokers == 1 {
            kind = HandDiscriminant::FiveOfAKind;
        }
        return kind;
    }
    if counts.contains(&3) {
        kind = match num_jokers {
            0 if counts.contains(&2) => HandDiscriminant::FullHouse,
            0 => HandDiscriminant::ThreeOfAKind,
            2 => HandDiscriminant::FiveOfAKind,
            1 => HandDiscriminant::FourOfAKind,
            _ => unreachable!("more than 2 jokers in a hand with 3 of a kind"),
        };
        return kind;
    }
    let num_pairs = counts.iter().filter(|x| **x == 2).count() / 2;
    if num_pairs == 2 {
        kind = HandDiscriminant::TwoPairs;
        if num_jokers == 1 {
            kind = HandDiscriminant::FullHouse;
        }
        return kind;
    }
    if num_pairs == 1 {
        kind = match num_jokers {
            3 => HandDiscriminant::FiveOfAKind,
            2 => HandDiscriminant::FourOfAKind,
            1 => HandDiscriminant::ThreeOfAKind,
            0 => HandDiscriminant::OnePair,
            _ => unreachable!("more than 3 jokers in a hand with 1 pair"),
        };
        return kind;
    }
    kind = match num_jokers {
        1 => HandDiscriminant::OnePair,
        2 => HandDiscriminant::ThreeOfAKind,
        3 => HandDiscriminant::FourOfAKind,
        _ => HandDiscriminant::HighCard,
    };
    return kind;
}

impl FromStr for Hand {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (_cards, bid) = s.split_once(" ").ok_or(anyhow!("failed to split"))?;
        let bid = bid.trim().parse::<u32>().context("failed to parse bid")?;
        let mut cards = [Card::A; 5];
        for (i, c) in _cards.chars().enumerate() {
            cards[i] = match c {
                'A' => Card::A,
                'K' => Card::K,
                'Q' => Card::Q,
                'J' => Card::J,
                'T' => Card::Num(10),
                _ => Card::Num(c.to_digit(10).unwrap() as u8),
            };
        }
        let kind = parse_hand(cards);
        Ok(Self { cards, kind, bid })
    }
}

fn main() -> anyhow::Result<()> {
    let mut line = String::new();
    let mut hands = Vec::new();
    while std::io::stdin().read_line(&mut line)? > 0 {
        let hand = line.parse::<Hand>()?;
        if hand.kind != HandDiscriminant::HighCard && hand.cards.contains(&Card::J) {
            dbg!(hand);
        }
        hands.push(hand);
        line.clear();
    }
    hands.sort();
    dbg!(&hands);
    let mut winnings = 0;
    for (i, hand) in hands.iter().rev().enumerate() {
        winnings += hand.bid * (i as u32 + 1);
    }
    dbg!(winnings);
    Ok(())
}
