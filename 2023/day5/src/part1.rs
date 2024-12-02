use anyhow::{anyhow, Context, Result};
use std::{io::Read, str::FromStr};

#[derive(Debug)]
struct Entry {
    dest: usize,
    src: usize,
    range: usize,
}

impl FromStr for Entry {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut parts = s.split(" ").map(|s| s.trim());
        let dest = parts.next().ok_or(anyhow!("no dest"))?.parse::<usize>()?;
        let src = parts.next().ok_or(anyhow!("no src"))?.parse::<usize>()?;
        let range = parts.next().ok_or(anyhow!("no range"))?.parse::<usize>()?;

        Ok(Entry { dest, src, range })
    }
}

impl Entry {
    fn get_next(&self, loc: usize) -> Option<usize> {
        dbg!(loc, self.src, self.range);

        let start = self.src;
        let end = self.src + self.range;

        if loc >= start && loc <= end {
            let offset = loc - start;
            Some(self.dest + offset)
        } else {
            None
        }
    }
}

#[derive(Debug)]
struct Map {
    from: String,
    to: String,
    entries: Vec<Entry>,
}

impl FromStr for Map {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut lines = s.lines();
        let name = lines.next().ok_or(anyhow!("no name"))?.to_string();
        let mut info = name
            .strip_suffix(" map:")
            .ok_or(anyhow!("No map title"))?
            .split("-");
        let from = info.next().ok_or(anyhow!("no from"))?.to_string();
        let to = info.skip(1).next().ok_or(anyhow!("no to"))?.to_string();
        let entries = lines
            .map(|s| s.parse::<Entry>())
            .collect::<Result<Vec<_>, _>>()?;
        Ok(Map { entries, to, from })
    }
}

impl Map {
    fn get_next(&self, loc: usize) -> Option<usize> {
        self.entries
            .iter()
            .find_map(|e| e.get_next(loc))
    }
}

#[derive(Debug)]
struct Almanac {
    maps: Vec<Map>,
}

impl Almanac {
    fn get_seed_loc(&self, seed: usize) -> Result<usize> {
        let mut loc = seed;
        for map in &self.maps {
            loc = map
                .get_next(loc)
                .unwrap_or(loc)
        }
        Ok(loc)
    }
}

fn parse_seeds(s: &str) -> Result<Vec<usize>> {
    s.split_once(": ")
        .ok_or(anyhow!("no seeds"))?
        .1
        .split(" ")
        .map(|s| s.trim().parse::<usize>())
        .collect::<Result<Vec<usize>, _>>()
        .context(anyhow!("no seeds"))
}

fn main() -> Result<()> {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;
    let mut almanac_blocks = input.split("\n\n");
    let seeds = parse_seeds(almanac_blocks.next().ok_or(anyhow!("no seeds"))?)?;
    dbg!(&seeds);
    let almanac = Almanac {
        maps: almanac_blocks
            .map(|s| s.parse::<Map>())
            .collect::<Result<Vec<_>, _>>()?,
    };
    let mut locs = vec![];
    for seed in seeds {
        let loc = almanac.get_seed_loc(seed)?;
        locs.push(loc);
        dbg!((seed, loc));
    }
    dbg!(locs.iter().min());

    Ok(())
}
