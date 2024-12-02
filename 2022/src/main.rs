use std::char::{ParseCharError, CharTryFromError};
use std::fs::File;
use std::io::Read;
use std::ops::Index;
use std::path::Path;
use std::str::FromStr;
use std;


const INPUT: &str = "./inputs/day2";

fn read_input() -> String {
    let mut input_fd = File::open(Path::new(INPUT)).expect("file exists");
    let mut nums_str = String::new(); 
    input_fd.read_to_string(&mut nums_str).expect("file readable");
    return nums_str;
}

#[derive(Debug,Clone)]
enum RPS {
    Rock,
    Paper,
    Scissors,
}

impl From<char> for RPS {
    fn from(c: char) -> Self {
        return c.try_into().unwrap();
    }
}

impl FromStr for RPS {
    type Err = &'static str;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        return if s.len() != 1 {
// {"failed to parse rock paper or scissors"}
            Err("couldn't parse Rock Paper Scissors")
        } else {
            match s.chars().nth(0) {
                Some('X') | Some('A') => Ok(Self::Rock),
                Some('Y') | Some('B') => Ok(Self::Paper),
                Some('Z') | Some('C') => Ok(Self::Scissors),
                None => Err("empty rock paper scissor"),
                _ => Err("Incorrect rock paper scissor"),

            }
        }
    }
}

#[derive(Debug,Clone)]
struct Round {
    ours: RPS,
    theirs: RPS,
}

impl FromStr for Round {
    type Err = &'static str;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        return if s.len() != 3 {
// {"failed to parse rock paper or scissors"}
            Err("couldn't parse Round")
        } else {
            let mut chars = s.chars();
            let theirs: RPS = chars.nth(0).ok_or("failed to parse rps")?.into();
            let ours: RPS = chars.nth(2).ok_or("failed to parse rps")?.into();
            return Ok(Self {ours, theirs});
        }
    }
}

pub fn main() {
    // let input = read_input();
    let input = include_str!("../inputs/day2");
    for line in input.split('\n'){
        let round = line.parse::<Round>();
        println!("{:?}",round.unwrap());
    }
}
