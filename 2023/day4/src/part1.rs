use anyhow::{anyhow, Result};

fn main() -> Result<()> {
    let mut line = String::new();

    let mut num_winners = vec![];

    while std::io::stdin().read_line(&mut line)? != 0 {
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
        line.clear();

        let mut count = 0;
        for h in have.iter() {
            for w in winners.iter() {
                if h == w {
                    count += 1;
                }
            }
        }
        num_winners.push(count);
    }
    let mut sum = 0;
    let num_cards = num_winners.len();
    let win_map = num_winners
        .into_iter()
        .map(|w| (0..w).into_iter().filter(|w| *w < num_cards).collect())
        .collect::<Vec<Vec<usize>>>();

    let mut queue = vec![0];

    while let Some(i) = queue.pop() {
        let new_cards = win_map[i].as_slice();
        queue.extend_from_slice(new_cards);
        sum += new_cards.len();
    }

    dbg!(sum);
    Ok(())
}
