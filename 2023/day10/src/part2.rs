use anyhow::{anyhow, Result};

const INPUT: &str = include_str!("../input.txt");

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
enum Dir {
    U,
    D,
    L,
    R,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
enum InOut {
    P,
    I,
    O,
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
    // let mut distance = vec![vec![0; w]; h];

    let mut queue = std::collections::VecDeque::<((usize, usize), Dir)>::new();

    if connects(&board, start, Dir::U) {
        queue.push_back(((start.0 - 1, start.1), Dir::U));
    }
    if connects(&board, start, Dir::L) {
        queue.push_back(((start.0, start.1 - 1), Dir::L));
    }
    if connects(&board, start, Dir::R) {
        queue.push_back(((start.0, start.1 + 1), Dir::R));
    }
    if connects(&board, start, Dir::D) {
        queue.push_back(((start.0 + 1, start.1), Dir::D));
    }

    visited[start.0][start.1] = true;
    // distance[start.0][start.1] = 0;

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
        if check_up && !has_visited(&visited, point, Dir::U) && connects(&board, point, Dir::U) {
            queue.push_back(((point.0 - 1, point.1), Dir::U));
        }
        if check_left
            && !has_visited(&visited, point, Dir::L)
            && connects(&board, point, Dir::L)
        {
            queue.push_back(((point.0, point.1 - 1), Dir::L));
        }
        if check_right
            && !has_visited(&visited, point, Dir::R)
            && connects(&board, point, Dir::R)
        {
            queue.push_back(((point.0, point.1 + 1), Dir::R));
        }
        if check_down
            && !has_visited(&visited, point, Dir::D)
            && connects(&board, point, Dir::D)
        {
            queue.push_back(((point.0 + 1, point.1), Dir::D));
        }

        visited[point.0][point.1] = true;
    }

    let mut enclosed = visited
        .iter()
        .map(|row| {
            row.iter()
                .map(|v| if *v { InOut::P } else { InOut::I })
                .collect::<Vec<InOut>>()
        })
        .collect::<Vec<_>>();
    print_board(&board, &enclosed);


    #[derive(Debug, PartialEq, Eq, Clone, Copy, Default)]
    struct Connections {
        r: bool,
        l: bool,
        u: bool,
        d: bool,
    }
    let connections = {
        let mut connections: Vec<Vec<Connections>> = vec![vec![Connections::default(); w]; h];
        for row in 0..h {
            for col in 0..w {
                if enclosed[row][col] != InOut::P {
                    continue;
                }
                let char = board[row][col];
                match char {
                    'F' => {
                        connections[row][col].r = true;
                        connections[row][col].d = true;
                    }
                    'L' => {
                        connections[row][col].r = true;
                        connections[row][col].u = true;
                    }
                    'J' => {
                        connections[row][col].l = true;
                        connections[row][col].u = true;
                    }
                    '7' => {
                        connections[row][col].l = true;
                        connections[row][col].d = true;
                    }
                    '-' => {
                        connections[row][col].r = true;
                        connections[row][col].l = true;
                    }
                    '|' => {
                        connections[row][col].u = true;
                        connections[row][col].d = true;
                    }
                    'S' => {
                    }
                    _ => unreachable!(),
                }
            }
        }

        if start.0 < h - 1 && connections[start.0 + 1][start.1].u {
            connections[start.0][start.1].d = true;
        }
        if start.0 > 0 && connections[start.0 - 1][start.1].d {
            connections[start.0][start.1].u = true;
        }
        if start.1 < w - 1 && connections[start.0][start.1 + 1].l {
            connections[start.0][start.1].r = true;
        }
        if start.1 > 0 && connections[start.0][start.1 - 1].r {
            connections[start.0][start.1].l = true;
        }
        connections
    };

    let mut lr_crosses = vec![vec![0; w]; h];

    for row in 0..h {
        let mut enter: Option<usize> = None;
        for col in 0..w {
            let conns = connections[row][col];
            if conns.u && conns.d {
                lr_crosses[row][col] = 1;
            } else if conns.u || conns.d {
                if let Some(start) = enter {
                    assert!(conns.l);
                    if connections[row][start].u != conns.u {
                        lr_crosses[row][col] = 1;
                    }
                    enter = None;
                } else {
                    assert!(conns.r);
                    enter = Some(col);
                }
            }
        }
    }


    for row in 0..h {
        let mut parity = 0;
        for col in 0..w {
            parity += lr_crosses[row][col];
            if enclosed[row][col] == InOut::I && parity % 2 == 0 {
                enclosed[row][col] = InOut::O;
            }
        }
    }

    println!("");
    print_board(&board, &enclosed);

    let mut count_inside = 0;
    for row in enclosed.iter() {
        for c in row.iter() {
            if *c == InOut::I {
                count_inside += 1;
            }
        }
    }
    dbg!(count_inside);

    Ok(())
}

fn translate_char(ch: char) -> char {
    return match ch {
        'F' => '┌',
        '7' => '┐',
        '|' => '│',
        '-' => '─',
        'J' => '┘',
        'L' => '└',
        '.' => '░',
        c => c,
    };
}

fn print_board(board: &Vec<Vec<char>>, enclosed: &Vec<Vec<InOut>>) {
    for (row, enc_row) in board.iter().zip(enclosed) {
        for (c, enc) in row.iter().zip(enc_row) {
            let c = if *enc == InOut::P {
                translate_char(*c)
            } else if *enc == InOut::O {
                '░'
            } else {
                '▓'
            };
            print!("{}", c);
        }
        println!();
    }
}

fn has_visited(visited: &Vec<Vec<bool>>, point: (usize, usize), dir: Dir) -> bool {
    let w = visited[0].len();
    let h = visited.len();

    return match dir {
        Dir::U => {
            if point.0 == 0 {
                true
            } else {
                visited[point.0 - 1][point.1]
            }
        }
        Dir::L => {
            if point.1 == 0 {
                true
            } else {
                visited[point.0][point.1 - 1]
            }
        }
        Dir::R => {
            if point.1 == w - 1 {
                true
            } else {
                visited[point.0][point.1 + 1]
            }
        }
        Dir::D => {
            if point.0 == h - 1 {
                true
            } else {
                visited[point.0 + 1][point.1]
            }
        }
    };
}

fn connects(board: &Vec<Vec<char>>, point: (usize, usize), dir: Dir) -> bool {
    let w = board[0].len();
    let h = board.len();

    let c = match dir {
        Dir::U => {
            if point.0 == 0 {
                '.'
            } else {
                board[point.0 - 1][point.1]
            }
        }
        Dir::L => {
            if point.1 == 0 {
                '.'
            } else {
                board[point.0][point.1 - 1]
            }
        }
        Dir::R => {
            if point.1 == w - 1 {
                '.'
            } else {
                board[point.0][point.1 + 1]
            }
        }
        Dir::D => {
            if point.0 == h - 1 {
                '.'
            } else {
                board[point.0 + 1][point.1]
            }
        }
    };

    return match c {
        '|' => dir == Dir::U || dir == Dir::D,
        '.' => false,
        '-' => dir == Dir::L || dir == Dir::R,
        'L' => dir == Dir::D || dir == Dir::L,
        'J' => dir == Dir::D || dir == Dir::R,
        'F' => dir == Dir::U || dir == Dir::L,
        '7' => dir == Dir::U || dir == Dir::R,
        'S' => unreachable!("Reached start!"),
        _ => unreachable!("unreachable char: {}", c),
    };
}
