use std::ops::{DerefMut, Deref};
use anyhow::Result;

#[derive(Debug, Clone)]
struct Grid(Vec<Vec<Cell>>);

impl DerefMut for Grid {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl Deref for Grid {
    type Target = Vec<Vec<Cell>>;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl Grid {
    fn new() -> Self {
        Self(vec![])
    }

    fn size(&self) -> (usize, usize) {
        (self.0[0].len(), self.0.len())
    }

    fn is_immediately_adjacent_to_symbol(&self, pos: (usize, usize)) -> bool {
        let size = self.size();
        let ordinals = [(1,0), (1,1), (0,1), (-1,1), (-1,0), (-1,-1), (0,-1), (1,-1)];

        for (x, y) in ordinals {
            let x = pos.0 as i32 + x;
            let y = pos.1 as i32 + y;
            if x < 0 || y < 0 || x >= size.0 as i32 || y >= size.1 as i32 {
                continue;
            }
            if let Cell::Symbol(_) = self[y as usize][x as usize] {
                return true;
            }
        }
        return false;
    }

    fn is_adjacent_to_symbol(&self, mut pos: (usize, usize)) -> bool {
        let size = self.size();

        while pos.0 < size.0 && matches!(self[pos.1][pos.0], Cell::Number(_)) {
            if self.is_immediately_adjacent_to_symbol(pos) {
                return true;
            }
            pos.0 += 1;
        }

        return false;
    }

    fn get_num(&self, mut pos: (usize, usize)) -> (u32, usize) {
        let size = self.size();
        let tmp = pos.0;
        let mut num = 0;
        assert!(matches!(self[pos.1][pos.0], Cell::Number(_)));
        while pos.0 < size.0 {
            match self[pos.1 as usize][pos.0 as usize] {
                Cell::Number(n) => {
                    num = num * 10 + n
                },
                _ => break
            }
            pos.0 += 1;
        }
        let skip = pos.0 - tmp;
        return (num, skip);
    }

    fn part_numbers(&self) -> Vec<u32> {
        let mut numbers = vec![];
        let mut skip = 0;

        for (r, row) in self.iter().enumerate() {
            for (c,cell) in row.iter().enumerate() {
                if skip > 0 {
                    skip -= 1;
                    continue;
                }
                if !matches!(cell, Cell::Number(_)) {
                    continue;
                }
                if self.is_adjacent_to_symbol((c, r)) {
                    let (num, num_len) = self.get_num((c, r));
                    numbers.push(num);
                    skip = num_len;
                }
            }
        }
        return numbers;
    }
}

#[derive(Debug, Clone)]
enum Cell {
    Number(u32),
    Symbol(char),
    Blank(char)
}

impl Cell {
    fn new(s: char) -> Result<Self> {
        match s {
            s if s.is_numeric() => Ok(Self::Number(s.to_digit(10).unwrap())),
            '.' => Ok(Self::Blank('.')),
            _ => Ok(Self::Symbol(s as char))
        }
    }
    fn from_str(s: &str) -> Result<Vec<Self>> {
        s.chars().map(|c| Self::new(c)).collect::<Result<Vec<Self>>>()
    }
}

fn main() -> Result<()> {
    let mut line = String::new();
    let mut grid = Grid::new();
    while let Ok(read) = std::io::stdin().read_line(&mut line) {
        if read == 0 {
            break;
        }
        {
            let line = line.trim();
            grid.push(Cell::from_str(line)?);
        }
        line.clear();
    }
    let sum = grid.part_numbers().iter().sum::<u32>();
    dbg!(sum);
    Ok(())
}
