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

    std.mem.sort(u32, A.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, B.items, {}, comptime std.sort.asc(u32));

    if (A.items.len != B.items.len) {
        unreachable;
    }

    try stdout.print("len: {d}\n", .{A.items.len});
    var distance: u32 = 0;
    for (A.items, B.items) |a, b| {
        distance += @max(a, b) - @min(a, b);
    }

    try stdout.print("distance: {d}\n", .{distance});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
