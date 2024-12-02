use anyhow::Result;
use glam::{IVec2, UVec2};
use std::{
    io::Read,
    ops::{Deref, DerefMut, Index, IndexMut},
};

#[derive(Debug, Clone)]
struct Grid {
    inner: Vec<Vec<Cell>>,
    lines: Vec<String>,
    size: UVec2,
}

impl DerefMut for Grid {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}

impl Deref for Grid {
    type Target = Vec<Vec<Cell>>;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Index<UVec2> for Grid {
    type Output = Cell;
    fn index(&self, index: UVec2) -> &Self::Output {
        &self.inner[index.y as usize][index.x as usize]
    }
}

impl IndexMut<UVec2> for Grid {
    fn index_mut(&mut self, index: UVec2) -> &mut Self::Output {
        &mut self.inner[index.y as usize][index.x as usize]
    }
}

impl std::str::FromStr for Grid {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut grid = Self::new();
        for line in s.lines() {
            grid.push_row(line);
        }
        Ok(grid)
    }
}

impl Grid {
    fn new() -> Self {
        Self {
            inner: vec![],
            lines: vec![],
            size: UVec2::ZERO,
        }
    }

    fn push_row(&mut self, line: &str) {
        self.inner.push(Cell::from_str(line).unwrap());
        self.lines.push(line.to_string());
        self.size.x = line.len() as u32;
        self.size.y += 1;
    }

    fn checked_add(&self, dir: IVec2, pos: UVec2) -> Option<UVec2> {
        let size = self.size;
        let pos: IVec2 = IVec2::new(pos.x as i32, pos.y as i32) + dir;
        let ok = pos.x >= 0 && pos.y >= 0 && pos.x < size.x as i32 && pos.y < size.y as i32;
        if ok {
            return Some((pos.x as u32, pos.y as u32).into());
        }
        return None;
    }

    fn adjacent_numbers(&self, pos: UVec2) -> Vec<u32> {
        let ordinals = [
            (0, 1),   // N
            (1, 0),   // E
            (1, 1),   // NE
            (0, -1),  // S
            (-1, 0),  // W
            (-1, -1), // SW
            (1, -1),  // SE
            (-1, 1),  // NW
        ];

        let mut nums = vec![];
        let mut ids = vec![];

        for dir in ordinals {
            let loc = match self.checked_add(dir.into(), pos) {
                Some(loc) => loc,
                // oob
                None => continue,
            };
            if let Cell::Number(_) = self[loc] {
                let (num, id) = self.get_num(loc);

                let mut found = false;
                for found_id in &ids {
                    if id == *found_id {
                        found = true;
                    }
                }
                if !found {
                    nums.push(num);
                    ids.push(id);
                }
            }
        }
        return nums;
    }

    #[allow(unused)]
    fn surroundings(&self, pos: UVec2) -> String {
        let mut s = vec![];
        for row in 0..=4 {
            let row = 2 - row;
            for col in 0..=6 {
                let col = col - 3;
                let loc = self.checked_add((col, row).into(), pos);
                let ch = match loc {
                    Some(cell_loc) => match self[cell_loc] {
                        Cell::Number(n) => (n as u8) + ('0' as u8),
                        Cell::Symbol(c) => c as u8,
                        Cell::Blank(c) => c as u8,
                        Cell::Gear(c) => c as u8,
                    },
                    None => ' ' as u8,
                };
                s.push(ch);
            }
            s.push('\n' as u8);
        }
        return String::from_utf8(s).unwrap();
    }

    fn get_num(&self, pos: UVec2) -> (u32, UVec2) {
        let size = self.size;
        let mut num = 0;
        assert!(matches!(self[pos], Cell::Number(_)));

        let mut start = pos;
        // for (;;)
        loop {
            if start.x == 0 {
                break;
            }
            if !matches!(self[(start.x - 1, start.y).into()], Cell::Number(_)) {
                break;
            }
            start.x -= 1;
        }

        let mut end = start;
        // >> endl;
        while end.x < size.x {
            match self[end] {
                Cell::Number(n) => {
                    num = num * 10 + n;
                }
                _ => break,
            }
            end.x += 1;
        }

        // dbg!((num, &self[pos.y]));
        let id = UVec2::new(start.x, pos.y);
        return (num, id);
    }

    fn gear_ratios(&self) -> Vec<u128> {
        let mut numbers = vec![];

        for (r, row) in self.iter().enumerate() {
            for (c, cell) in row.iter().enumerate() {
                let pos = (c as u32, r as u32).into();
                if !matches!(cell, Cell::Gear(_)) {
                    continue;
                }
                let adjacent_numbers = self.adjacent_numbers(pos);
                if adjacent_numbers.len() == 2 {
                    let ratioed = (adjacent_numbers[0] as u128) * (adjacent_numbers[1] as u128);
                    numbers.push(ratioed);
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
    Blank(char),
    Gear(char),
}

impl Cell {
    fn new(s: char) -> Result<Self> {
        match s {
            s if s.is_numeric() => Ok(Self::Number(s.to_digit(10).unwrap())),
            '*' => Ok(Self::Gear('*')),
            '.' => Ok(Self::Blank('.')),
            _ => Ok(Self::Symbol(s as char)),
        }
    }
    fn from_str(s: &str) -> Result<Vec<Self>> {
        s.trim()
            .chars()
            .map(|c| Self::new(c))
            .collect()
    }
}

fn main() -> Result<()> {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;
    let grid = input.parse::<Grid>()?;

    let sum = grid.gear_ratios().iter().sum::<u128>();
    dbg!(sum);
    Ok(())
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_add() {
        let mut grid = Grid::new();
        grid.size = UVec2::new(10, 10);
        assert!(matches!(
            grid.checked_add(IVec2::new(1, 0), UVec2::new(9, 0)),
            None
        ));
        assert!(matches!(
            grid.checked_add(IVec2::new(1, 0), UVec2::new(10, 0)),
            None
        ));
        assert!(matches!(
            grid.checked_add(IVec2::new(-1, 0), UVec2::ZERO),
            None
        ));
        assert_eq!(
            grid.checked_add(IVec2::new(-1, 0), UVec2::new(1, 0)),
            Some(UVec2::ZERO)
        );
    }
}
