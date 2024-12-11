const std = @import("std");

const input = @embedFile("./input.txt");

const BLINK_COUNT: usize = 75;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    const Stones = std.AutoHashMap(usize, usize);
    var stones = Stones.init(alloc);

    {
        var stone_iter = std.mem.tokenizeScalar(u8, input, ' ');
        while (stone_iter.next()) |stone_str| {
            const stone = try std.fmt.parseUnsigned(usize, stone_str, 10);
            try stones.put(stone, 1);
        }
    }

    for (0..BLINK_COUNT) |_| {
        var new_stones = Stones.init(alloc);
        try new_stones.ensureTotalCapacity(stones.count() * 2);
        defer {
            stones.deinit();
            stones = new_stones;
        }
        var iter = stones.iterator();
        while (iter.next()) |init_stone| {
            var stone = init_stone.key_ptr.*;
            const count = init_stone.value_ptr.*;
            defer {
                const entry = new_stones.getOrPutAssumeCapacity(stone);
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }
                entry.value_ptr.* += count;
            }
            if (stone == 0) {
                stone = 1;
                continue;
            }
            const d = std.math.log10_int(stone);
            if (d % 2 == 1) {
                const m = std.math.pow(u64, 10, (d + 1) / 2);
                stone = stone % m;
                const entry = new_stones.getOrPutAssumeCapacity(stone / m);
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }
                entry.value_ptr.* += count;
                continue;
            }

            stone = stone * 2024;
        }
    }

    var count: usize = 0;

    var value_iter = stones.valueIterator();

    while (value_iter.next()) |stone_count| {
        count += stone_count.*;
    }

    try stdout.print("count = {}\n", .{count});

    try bw.flush();
}
