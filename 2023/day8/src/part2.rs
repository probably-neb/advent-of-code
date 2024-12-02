use std::io::Read;

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

// function gcd(a, b){
//     // Euclidean algorithm
//     while (b != 0){
//         var temp = b;
//         b = a % b;
//         a = temp;
//     }
//     return a;
// }
//
// function lcm(a, b){
//     return (a * b / gcd(a, b));
// }
//
// function lcmm(args){
//     // Recursively iterate through pairs of arguments
//     // i.e. lcm(args[0], lcm(args[1], lcm(args[2], args[3])))
//
//     if(args.length == 2){
//         return lcm(args[0], args[1]);
//     } else {
//         var arg0 = args[0];
//         args.shift();
//         return lcm(arg0, lcmm(args));
//     }
// }

fn gcm(a: u128, b: u128) -> u128 {
    let mut a = a;
    let mut b = b;
    while b != 0 {
        (a, b) = (b, a % b);
    }
    a
}

fn lcm(a: u128, b: u128) -> u128 {
    (a * b) / gcm(a, b)
}

fn lcmm(args: &[u128]) -> u128 {
    if args.len() == 2 {
        lcm(args[0], args[1])
    } else {
        lcm(args[0], lcmm(&args[1..]))
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
    let key_id = |key: &str| -> usize { keys.iter().position(|&k| k == key).expect("key exists") };
    for line in lines.skip(1) {
        let (_, path) = line.trim().split_once(" = ").unwrap();
        let (l, r) = path[1..path.len() - 1]
            .split_once(", ")
            .map(|(l, r)| (key_id(l), key_id(r)))
            .unwrap();
        steps.push((l, r));
    }
    let mut num_steps = 0;
    let mut cur_keys = keys
        .iter()
        .enumerate()
        .filter_map(|(i, k)| k.ends_with("A").then(|| i))
        .collect::<Vec<usize>>();
    let mut steps_to_z = vec![0; cur_keys.len()];
    while !cur_keys.iter().all(|&k| keys[k].ends_with("Z")) {
        let inst = path.next().unwrap();
        for (i, key) in cur_keys.iter_mut().enumerate() {
            if steps_to_z[i] > 0 {
                continue;
            }
            let (l, r) = steps[*key];
            // dbg!((inst, (&keys[l], &keys[r])));
            *key = match inst {
                Inst::L => l,
                Inst::R => r,
            };
            if keys[*key].ends_with("Z") {
                steps_to_z[i] = num_steps + 1;
                dbg!((i, num_steps + 1));
            }
        }
        num_steps += 1;
    }
    dbg!(&steps_to_z);
    let num_steps = lcmm(&steps_to_z);
    dbg!(num_steps);
}
