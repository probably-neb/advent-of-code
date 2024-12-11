const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // const alloc = std.heap.page_allocator;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    var safe_count: u32 = 0;

    while (line_iter.next()) |line| {
        var prev: ?u32 = null;

        var all_inc = true;
        var all_dec = true;
        var all_range = true;

        var num_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (num_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(u32, num_str, 10);
            if (prev) |prev_num| {
                all_inc = num > prev_num and all_inc;
                all_dec = num < prev_num and all_dec;
                const diff = @max(num, prev_num) - @min(num, prev_num);
                all_range = (diff == 1 or diff == 2 or diff == 3) and all_range;
            }
            prev = num;
        }
        safe_count += @intFromBool((all_inc or all_dec) and all_range);
    }

    try stdout.print("safe count: {}\n", .{safe_count});

    try bw.flush(); // don't forget to flush!
}
