use std::io::Read;

use anyhow::{anyhow, Result};

fn parse_line(line: &str) -> Result<usize> {
    let (_card, numbers) = line.split_once(": ").ok_or(anyhow!("no ': '"))?;
    let (winners, have) = numbers.split_once(" | ").ok_or(anyhow!("no ' | '"))?;
    let have: Vec<u32> = have
        .split_whitespace()
        .map(|n| {
            n.trim()
                .parse()
                .map_err(|_| anyhow!("could not parse '{}'", n))
        })
        .collect::<Result<Vec<u32>>>()?;
    let winners: Vec<u32> = winners
        .split_whitespace()
        .map(|n| {
            n.trim()
                .parse()
                .map_err(|_| anyhow!("could not parse '{}'", n))
        })
        .collect::<Result<Vec<u32>>>()?;

    let mut count = 0;
    for h in have.iter() {
        if winners.contains(h) {
            count += 1;
        }
    }
    return Ok(count);
}

fn main() -> Result<()> {
    let mut input = String::new();

    std::io::stdin().read_to_string(&mut input)?;

    let lines = input.lines().collect::<Vec<_>>();

    let mut counts = vec![0; lines.len()];

    for (li, line) in lines.iter().enumerate() {
        let cards_won = parse_line(line)?;

        for i in 0..cards_won {
            let i = i + li + 1;
            if i < lines.len() {
                counts[i] += 1 + counts[li];
            }
        }
    }
    let sum = counts.into_iter().sum::<usize>() + lines.len();

    dbg!(sum);
    Ok(())
}
