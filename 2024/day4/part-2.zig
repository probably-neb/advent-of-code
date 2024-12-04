const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    // const XMAS = [6]u8;

    var count: usize = 0;

    var lines_list = std.ArrayList([]const u8).init(alloc);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (line_iter.next()) |line| {
        try lines_list.append(line);
        // try stdout.print("{s}\n", .{line});
    }

    const lines = lines_list.items;
    const line_width = lines[0].len;

    for (0..line_width - 2) |col| {
        for (0..lines.len - 2) |row| {
            var a: [3]u8 = undefined;
            a[0] = lines[row][col];
            a[1] = lines[row + 1][col + 1];
            a[2] = lines[row + 2][col + 2];

            const a_ok = std.mem.eql(u8, &a, "MAS") or std.mem.eql(u8, &a, "SAM");

            var b: [3]u8 = undefined;
            b[0] = lines[row][col + 2];
            b[1] = lines[row + 1][col + 1];
            b[2] = lines[row + 2][col];

            const b_ok = std.mem.eql(u8, &b, "MAS") or std.mem.eql(u8, &b, "SAM");

            count += @intFromBool(a_ok and b_ok);
        }
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
