use anyhow::{anyhow, Result};
use std::{io::Read, str::FromStr};

#[derive(Debug, Copy, Clone)]
enum Inst {
    L,
    R,
}

fn char_to_inst(c: char) -> Inst {
    match c {
        'L' => Inst::L,
        'R' => Inst::R,
        _ => panic!("not L or R"),
    }
}
impl FromStr for Inst {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "L" => Ok(Inst::L),
            "R" => Ok(Inst::R),
            _ => Err(anyhow!("not L or R")),
        }
    }
}

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();
    let mut lines = input.lines();

    let mut steps = Vec::new();
    let mut keys = Vec::new();

    let mut path = lines
        .next()
        .unwrap()
        .trim()
        .chars()
        .map(char_to_inst)
        .cycle();

    for line in lines.clone().skip(1) {
        let (key, _) = line.trim().split_once(" = ").unwrap();
        keys.push(key);
    }
    let key_id = |key: &str| -> usize {
        keys.iter().position(|&k| k == key).expect("key exists")
    };
    for line in lines.skip(1) {
        let (key, path) = line.trim().split_once(" = ").unwrap();
        let (l, r) = path[1..path.len() - 1].split_once(", ").unwrap();
        let (l, r) = (key_id(l), key_id(r));
        steps.push((l, r));
    }
    let mut num_steps = 0;
    let mut key = key_id("AAA");
    let end = key_id("ZZZ");
    while key != end {
        let (l, r) = steps[key];
        let inst = path.next().unwrap();
        dbg!((inst, (&keys[l], &keys[r])));
        key = match inst {
            Inst::L => l,
            Inst::R => r,
        };
        num_steps += 1;
    }
    dbg!(num_steps);
}
