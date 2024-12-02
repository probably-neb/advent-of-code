const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const ArrayList = std.ArrayList;

fn parse_nums(alloc: mem.Allocator, str: []u8) !ArrayList(u32) {
    var line = mem.split(u8, str, " ");
    // skip label
    _ = line.next();
    var nums = ArrayList(u32).init(alloc);
    while (line.next()) |maybe_num| {
        if (maybe_num.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(u32, maybe_num, 10);
        try nums.append(num);
    }
    return nums;
}

fn get_distance(total_time: u32, time_held: u32) u32 {
    return (total_time - time_held) * time_held;
}

fn num_winning_options(total_time: u32, record: u32) u32 {
    var winning_options: u32 = 0;
    var time_held: u32 = 0;
    while (time_held <= total_time) : (time_held += 1) {
        if (get_distance(total_time, time_held) > record) {
            winning_options += 1;
        }
    }
    return winning_options;
}

pub fn main() !void {
    const alloc = std.heap.page_allocator;
    const stdin = std.io.getStdIn();
    const rdr = stdin.reader();
    const times_str = try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 1_000_000);
    const distances_str = try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', 1_000_000);
    const times = try parse_nums(alloc, times_str.?);
    const distances = try parse_nums(alloc, distances_str.?);
    var da_answa: ?u32 = null;
    for (times.items, distances.items) |time, record| {
        const winning_options = num_winning_options(time, record);
        // print("t={d}, d={d} => {any}\n", .{ time, record, winning_options });
        da_answa = (da_answa orelse 1) * winning_options;
    }
    print("da answa: {?d}\n", .{da_answa});
}
