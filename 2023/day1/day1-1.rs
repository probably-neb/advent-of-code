fn main() {
    let input = include_str!("day1-1.in");
    let mut sum = 0;
    for line in input.lines() {
        let mut first: u8 = 0;
        let mut last: u8 = 0;

        let mut chars = line.as_bytes().to_vec();

        for c in &chars {
            match *c as char {
                '0'..='9' => last = c - '0' as u8,
                _ => continue
            }
        }
        
        chars.reverse();
        for c in chars,  {
            match c as char {
                '0'..='9'=> first = c - '0' as u8,
                _ => continue
            }
        }
        let num: u32 = (first * 10 + last ) as u32;
        println!("{line} {num}");
        sum += num;
    }
    println!("{}", sum);
}
