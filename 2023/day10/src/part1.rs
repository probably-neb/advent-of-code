use anyhow::{anyhow, Result};

const INPUT: &str = include_str!("../input.txt");

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
enum Dir {
    Up,
    Down,
    Left,
    Right,
}

fn main() -> Result<()> {


    let mut start: (usize, usize) = (0, 0);

    let board = {
        let mut board: Vec<Vec<char>> = vec![];
        for line in INPUT.lines() {
            let chars: Vec<char> = line.chars().collect();
            for (i, c) in chars.iter().enumerate() {
                if *c == 'S' {
                    start = (board.len(), i);
                }
            }
            board.push(chars);
        }
        // assert!(start.0 != 0 && start.1 != 0);
        board
    };

    let w = board[0].len();
    let h = board.len();

    let mut visited = vec![vec![false; w]; h];
    let mut distance = vec![vec![0; w]; h];

    let mut queue = std::collections::VecDeque::<((usize, usize), Dir)>::new();

    // let get = |point: (usize, usize), dir: Dir| -> char {
    //     return match dir {
    //         Dir::Up => if point.0 == 0 { '.' } else { board[point.0 - 1][point.1] },
    //         Dir::Left => if point.1 == 0 { '.' } else { board[point.0][point.1 - 1] },
    //         Dir::Right => if point.1 == w - 1 { '.' } else { board[point.0][point.1 + 1] },
    //         Dir::Down => if point.0 == h - 1 { '.' } else { board[point.0 + 1][point.1] },
    //     }
    // };


    if connects(&board, start, Dir::Up) {
        queue.push_back(((start.0 -1, start.1), Dir::Up));
    }
    if connects(&board, start, Dir::Left) {
        queue.push_back(((start.0, start.1 - 1), Dir::Left));
    }
    if connects(&board, start, Dir::Right) {
        queue.push_back(((start.0, start.1 + 1), Dir::Right));
    }
    if connects(&board, start, Dir::Down) {
        queue.push_back(((start.0 + 1, start.1), Dir::Down));
    }

    visited[start.0][start.1] = true;
    distance[start.0][start.1] = 0;

    while let Some((point, from_dir)) = queue.pop_front() {
        let char = board[point.0][point.1];
        let (check_left, check_right, check_up, check_down) = match char {
            '.' => unreachable!("checking '.' at {:?} from {:?}", point, from_dir),
            'S' => unreachable!("checking 'S' at {:?} from {:?}", point, from_dir),
            '|' => (false, false, true, true),
            '-' => (true, true, false, false),
            'L' => (false, true, true, false),
            'J' => (true, false, true, false),
            'F' => (false, true, false, true),
            '7' => (true, false, false, true),
            _ => unreachable!("unreachable char: {}", char),
        };
        if check_up && !has_visited(&visited, point, Dir::Up) && connects(&board, point, Dir::Up) {
            queue.push_back(((point.0 - 1, point.1), Dir::Up));
        }
        if check_left && !has_visited(&visited, point, Dir::Left) && connects(&board, point, Dir::Left) {
            queue.push_back(((point.0, point.1 - 1), Dir::Left));
        }
        if check_right && !has_visited(&visited, point, Dir::Right) && connects(&board, point, Dir::Right) {
            queue.push_back(((point.0, point.1 + 1), Dir::Right));
        }
        if check_down && !has_visited(&visited, point, Dir::Down) && connects(&board, point, Dir::Down) {
            queue.push_back(((point.0 + 1, point.1), Dir::Down));
        }

        visited[point.0][point.1] = true;
        distance[point.0][point.1] = match from_dir {
            Dir::Left => distance[point.0][point.1 + 1] + 1,
            Dir::Right => distance[point.0][point.1 - 1] + 1,
            Dir::Up => distance[point.0 + 1][point.1] + 1,
            Dir::Down => distance[point.0 - 1][point.1] + 1,
        };
    }

    dbg_board(&board);
    dbg_board(&visited);
    dbg_board(&distance);

    let mut max_dist: usize = 0;
    for i in 0..h {
        for j in 0..w {
            max_dist = std::cmp::max(max_dist, distance[i][j]);
        }
    }

    dbg!(&start);

    dbg!(max_dist);
    Ok(())
}

fn dbg_board<T: std::fmt::Display>(board: &Vec<Vec<T>>) {
    for line in board {
        for c in line {
            print!("{} ", c);
        }
        println!();
    }
}

fn has_visited (visited: &Vec<Vec<bool>>, point: (usize, usize), dir: Dir ) -> bool {
    let w = visited[0].len();
    let h = visited.len();

    return match dir {
        Dir::Up => if point.0 == 0 { true } else { visited[point.0 - 1][point.1] },
        Dir::Left => if point.1 == 0 { true } else { visited[point.0][point.1 - 1] },
        Dir::Right => if point.1 == w - 1 { true } else { visited[point.0][point.1 + 1] },
        Dir::Down => if point.0 == h - 1 { true } else { visited[point.0 + 1][point.1] },
    }
}

fn connects(board: &Vec<Vec<char>>, point: (usize, usize), dir: Dir) -> bool {
    let w = board[0].len();
    let h = board.len();

    let c = match dir {
        Dir::Up => if point.0 == 0 { '.' } else { board[point.0 - 1][point.1] },
        Dir::Left => if point.1 == 0 { '.' } else { board[point.0][point.1 - 1] },
        Dir::Right => if point.1 == w - 1 { '.' } else { board[point.0][point.1 + 1] },
        Dir::Down => if point.0 == h - 1 { '.' } else { board[point.0 + 1][point.1] },
    };

    return match c {
        '|' => dir == Dir::Up || dir == Dir::Down,
        '.' => false,
        '-' => dir == Dir::Left || dir == Dir::Right,
        'L' => dir == Dir::Down || dir == Dir::Left,
        'J' => dir == Dir::Down || dir == Dir::Right,
        'F' => dir == Dir::Up || dir == Dir::Left,
        '7' => dir == Dir::Up || dir == Dir::Right,
        'S' => unreachable!("Reached start!"),
        _ => unreachable!("unreachable char: {}", c),
    };
}
