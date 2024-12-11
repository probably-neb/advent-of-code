const std = @import("std");

const input = @embedFile("./input-smol.txt");

const BLINK_COUNT: usize = 25;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var stones = std.ArrayList(usize).init(alloc);

    {
        var stone_iter = std.mem.tokenizeScalar(u8, input, ' ');
        while (stone_iter.next()) |stone_str| {
            const stone = try std.fmt.parseUnsigned(usize, stone_str, 10);
            try stones.append(stone);
        }
    }

    for (0..BLINK_COUNT) |_| {
        var i: usize = 0;
        while (i < stones.items.len) : (i += 1) {
            const stone = stones.items[i];
            if (stone == 0) {
                stones.items[i] = 1;
                continue;
            }
            const digit_count = count_digits(stone);
            if (digit_count % 2 == 0) {
                const split_stones = split_num(stone, digit_count / 2);
                stones.items[i] = split_stones[0];
                try stones.insert(i + 1, split_stones[1]);
                i += 1;
                continue;
            }

            stones.items[i] = stone * 2024;
        }
    }

    try stdout.print("count = {}\n", .{stones.items.len});

    try bw.flush();
}

fn count_digits(_val: usize) usize {
    var val = _val;
    if (val == 0) return 1;
    var digits: usize = 0;
    while (val > 0) {
        val /= 10;
        digits += 1;
    }
    return digits;
}

fn split_num(val: usize, digits: usize) [2]usize {
    var removed: usize = 0;
    var front = val;

    while (removed < digits) {
        front /= 10;
        removed += 1;
    }

    const back = val - (front * std.math.pow(usize, 10, removed));

    return .{ front, back };
}

test count_digits {
    try std.testing.expectEqual(3, count_digits(123));
    try std.testing.expectEqual(1, count_digits(1));
    try std.testing.expectEqual(4, count_digits(1234));
}

test split_num {
    try std.testing.expectEqualDeep(.{ 1, 2 }, split_num(12, 1));
    try std.testing.expectEqualDeep(.{ 12, 34 }, split_num(1234, 2));
}
