fn main() {
    let mut idx = 0;
    for i in 0_u128..9_000_000_000_u128 {
        if i % 1_000_000_000 == 0 {
            idx += 1;
        }
    }
    println!("idx: {}", idx);
}
