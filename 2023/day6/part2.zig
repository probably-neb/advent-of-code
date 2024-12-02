const std = @import("std");
const print = std.debug.print;
const mem = std.mem;
const ArrayList = std.ArrayList;

fn parse_nums(str: []u8) !u64 {
    var line = mem.split(u8, str, " ");
    // skip label
    _ = line.next();
    var i: usize = 0;
    while (line.next()) |maybe_num| {
        const is_whitespace: bool = for (maybe_num) |digit| {
            if (std.ascii.isWhitespace(digit)) {
                break true;
            }
        } else false;
        if (maybe_num.len == 0 or is_whitespace) {
            continue;
        }
        @memcpy(str[i .. i + maybe_num.len], maybe_num);
        i += maybe_num.len;
    }
    const num = try std.fmt.parseInt(u64, str[0..i], 10);
    return num;
}

fn get_distance(total_time: u64, time_held: u64) u64 {
    return (total_time - time_held) * time_held;
}

fn num_winning_options(total_time: u64, record: u64) u64 {
    var winning_options: u64 = 0;
    var time_held: u64 = 0;
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

    const times_str = try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', std.math.maxInt(usize));
    const distances_str = try rdr.readUntilDelimiterOrEofAlloc(alloc, '\n', std.math.maxInt(usize));

    const time = try parse_nums(times_str.?);
    const record = try parse_nums(distances_str.?);
    var da_answa: ?u64 = null;
    const winning_options = num_winning_options(time, record);
    print("t={d}, d={d} => {any}\n", .{ time, record, winning_options });
    da_answa = (da_answa orelse 1) * winning_options;
    print("da answa: {?d}\n", .{da_answa});
}
