fn value(char_str: &str) -> u8 {
    match char_str {
        "one" => 1,
        "two" => 2,
        "three" => 3,
        "four" => 4,
        "five" => 5,
        "six" => 6,
        "seven" => 7,
        "eight" => 8,
        "nine" => 9,
        _ => 0
    }
}


fn main() {
    let input = include_str!("./day1-1.in");
    let mut sum = 0;
    for line in input.lines() {
        let mut first: u8 = 0;
        let mut first_index: usize = line.len();
        let mut last: u8 = 0;
        let mut last_index: usize = 0;

        let mut chars = line.as_bytes().to_vec();
        let char_strs = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"];

        'goto_considered_harmful: for i in 0..chars.len() {
            for char_str in char_strs {
                if chars[i..].starts_with(char_str.as_bytes()) {
                    // println!("first={} @{i}", char_str);
                    first_index = i;
                    first = value(char_str);
                    break 'goto_considered_harmful;
                }
            }
        }

        for (i, c) in chars.iter().enumerate() {
            match *c as char {
                '0'..='9' if i < first_index => {
                    first = c - '0' as u8;
                    break;
                },
                _ => continue
            }
        }

        for i in 0..chars.len() {
            for char_str in char_strs {
                if chars[i..].starts_with(char_str.as_bytes()) {
                    last_index = i;
                    last = value(char_str);
                }
            }
        }
        
        for i in (0..chars.len()).rev() {
            let c = chars[i];
            match c as char {
                '0'..='9' if i > last_index || last_index == 0 => {
                    last = c - '0' as u8;
                    break;
                },
                _ => continue
            }
        }
        let num: u32 = (first * 10 + last ) as f32;
        println!("{line} {num}");
        sum += num;
    }
    println!("{}", sum);
}
