const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    const Test = struct {
        val: usize,
        nums: []usize,
    };
    var tests_list = std.ArrayList(Test).init(alloc);

    while (line_iter.next()) |line| {
        const col_idx = std.mem.indexOfScalar(u8, line, ':').?;
        const num_str = line[0..col_idx];
        const rest = line[col_idx + 1 ..];

        const val = std.fmt.parseInt(usize, num_str, 10) catch unreachable;

        var nums_iter = std.mem.tokenizeScalar(u8, rest, ' ');

        var count_nums: usize = 0;
        while (nums_iter.next()) |_| : (count_nums += 1) {}

        var num_idx: u32 = 0;
        nums_iter.reset();

        var nums = try alloc.alloc(usize, count_nums);

        while (nums_iter.next()) |num| : (num_idx += 1) {
            nums[num_idx] = try std.fmt.parseInt(usize, num, 10);
        }

        try tests_list.append(.{ .val = val, .nums = nums });
    }

    const Op = enum {
        mul,
        add,
        con,
    };

    var count: usize = 0;

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var scratch = arena.allocator();

    for (tests_list.items) |tst| {
        defer _ = arena.reset(.retain_capacity);
        const val = tst.val;
        var ops = try scratch.alloc(Op, tst.nums.len - 1);

        const combinations_count = std.math.pow(usize, 3, ops.len);

        // std.debug.print("{}:\n", .{val});

        var i: usize = 0;
        while (i < combinations_count) : (i += 1) {
            var tmp = i;
            var j: usize = 0;
            while (j < ops.len) : (j += 1) {
                ops[ops.len - 1 - j] = switch (tmp % 3) {
                    0 => .mul,
                    1 => .add,
                    2 => .con,
                    else => unreachable,
                };
                tmp /= 3;
            }

            // std.debug.print("\t{}", .{tst.nums[0]});
            // for (tst.nums[1..], ops) |num, op| {
            //     const op_ch: u8 = switch (op) {
            //         .mul => '*',
            //         .add => '+',
            //     };
            //     std.debug.print(" {c} {}", .{ op_ch, num });
            // }
            var sum: usize = tst.nums[0];
            for (tst.nums[1..], ops) |num, op| {
                switch (op) {
                    .mul => sum = sum * num,
                    .add => sum = sum + num,
                    .con => sum = concatenate_numbers(sum, num),
                }
            }
            // std.debug.print(" = {}\n", .{sum});
            if (sum == val) {
                count += val;
                break;
            }
        }
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

fn concatenate_numbers(a: usize, b: usize) usize {
    var digits: u32 = 10;
    var temp = b;
    while (temp >= 10) {
        digits *= 10;
        temp /= 10;
    }
    return a * digits + b;
}

test concatenate_numbers {
    try std.testing.expectEqual(12, concatenate_numbers(1, 2));
}
