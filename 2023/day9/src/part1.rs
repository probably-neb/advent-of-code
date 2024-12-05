use anyhow::{anyhow, Result};

const INPUT: &str = include_str!("../input.txt");

fn main() -> Result<()> {

    let mut count: isize = 0;
    
    for line in INPUT.lines() {
        let nums = line.trim().split_ascii_whitespace()
                .map(|n| n.trim().parse().map_err(|_| anyhow!("could not parse '{}'", n)))
                .collect::<Result<Vec<i32>>>()?;
        let mut seqs = vec![nums];

        while seqs.last().unwrap().iter().filter(|&&r| r != 0).count() > 0 {
            let seq = seqs.last().unwrap();
            let mut new_seq: Vec<i32> = vec![0; seq.len() - 1];

            for i in 0..(seq.len() - 1) {
                let diff = seq[i + 1] - seq[i];
                new_seq[i] = diff;
            }
            dbg!(&new_seq);
            seqs.push(new_seq);
        }

        for i in (0..seqs.len() - 1).rev() {
            let next_last = *seqs.get(i + 1).unwrap().last().unwrap();
            let mut seq = seqs.get_mut(i).unwrap();
            let elem = *seq.last().unwrap() + next_last;
            seq.push(elem);
        }
        count += *seqs[0].last().unwrap() as isize;
        dbg!(seqs);
    }

    dbg!(count);
    Ok(())
}
