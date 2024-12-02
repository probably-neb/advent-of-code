use std::fs;
use std::fs::{File, OpenOptions};
use std::io;
use std::io::prelude::*;
use std::os::unix;
use std::path::Path;
use std::env;

const INPUT: &str = "./input/day1";
fn trickle_up(arr: &mut [usize; 3]) {
    if arr[0] > arr[2] || arr[0] > arr[1] {
        arr.swap(0,1);
    }
    if arr[1] > arr[2] {
        arr.swap(1,2);
    }
}

pub fn day1() {
    // let input_path = env::args().nth(1).expect("file path passed");
    let mut input_fd = File::open(Path::new(INPUT)).expect("file exists");
    let mut nums_str = String::new(); 
    input_fd.read_to_string(&mut nums_str).expect("file readable");
    let counts =  nums_str.split('\n');
    let mut biggest_bois_cals: [usize; 3] = Default::default();
    let mut cur_elf = 0;
    for count in counts {
        match count.parse::<usize>().ok() {
            Some(calories) => cur_elf += calories,
            None => {
                biggest_bois_cals[0] = usize::max(biggest_bois_cals[0], cur_elf);
                trickle_up(&mut biggest_bois_cals);
                cur_elf = 0;
            }
        }
    }
    println!("{biggest_bois_cals:?}");
    println!("total: {:?}", biggest_bois_cals.iter().sum::<usize>());
    // println!("{:?}", nums_str.split("\n\n"));
}
