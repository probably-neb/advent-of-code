const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var A = std.ArrayList(u32).init(alloc);
    var B = std.ArrayList(u32).init(alloc);

    var iter = std.mem.tokenizeScalar(u8, input, '\n');

    while (iter.next()) |line| {
        var num_iter = std.mem.tokenizeScalar(u8, line, ' ');
        const a = std.fmt.parseUnsigned(u32, num_iter.next().?, 10) catch unreachable;
        const b = std.fmt.parseUnsigned(u32, num_iter.next().?, 10) catch unreachable;

        A.append(a) catch unreachable;
        B.append(b) catch unreachable;
    }

    var similarity: u32 = 0;

    for (A.items) |a| {
        var count: u32 = 0;
        for (B.items) |b| {
            if (a == b) {
                count += 1;
            }
        }
        similarity += a * count;
    }

    try stdout.print("similarity: {d}\n", .{similarity});

    try bw.flush(); // don't forget to flush!
}
