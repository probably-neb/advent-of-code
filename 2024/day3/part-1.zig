const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // const alloc = std.heap.page_allocator;
    // var muls_list = std.ArrayList([]const u8).init(alloc);
    var count: u32 = 0;

    var char_index: u32 = 0;
    var c: u8 = 0;
    while (char_index < (input.len - "mul(x,x)".len)) : (char_index += 1) {
        c = input[char_index];
        if (c != 'm') {
            continue;
        }
        c = input[char_index + 1];
        if (c != 'u') {
            continue;
        }
        c = input[char_index + 2];
        if (c != 'l') {
            continue;
        }
        c = input[char_index + 3];
        if (c != '(') {
            continue;
        }

        var i: u32 = 4;
        for (0..3) |_| {
            c = input[char_index + i];
            if (!std.ascii.isDigit(c)) {
                break;
            }
            i += 1;
        }
        c = input[char_index + i];
        if (c != ',') {
            continue;
        }
        // std.debug.print("found ,\n", .{});
        i += 1;
        for (0..3) |_| {
            c = input[char_index + i];
            if (!std.ascii.isDigit(c)) {
                break;
            }
            i += 1;
        }
        c = input[char_index + i];
        if (c != ')') {
            continue;
        }
        const mul = input[char_index..][0 .. i + 1];
        const comma_index = std.mem.indexOfScalar(u8, mul, ',').?;
        const a = try std.fmt.parseInt(u32, mul["mul(".len..comma_index], 10);
        const b = try std.fmt.parseInt(u32, mul[comma_index + 1 .. mul.len - 1], 10);

        count += a * b;
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

fn dbg(comptime fmt: []const u8, val: anytype) @TypeOf(val) {
    _ = fmt;
    // std.debug.print(fmt, .{val});
    return val;
}
