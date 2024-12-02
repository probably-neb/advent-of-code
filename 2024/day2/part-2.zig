const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    var safe_count: u32 = 0;

    var nums_list = std.ArrayList(u32).init(alloc);

    var arena = std.heap.ArenaAllocator.init(alloc);
    const arena_alloc = arena.allocator();

    outer: while (line_iter.next()) |line| {
        defer nums_list.clearRetainingCapacity();
        defer _ = arena.reset(.retain_capacity);
        var num_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (num_iter.next()) |num_str| {
            const num = try std.fmt.parseInt(u32, num_str, 10);
            try nums_list.append(num);
        }

        const buf = try arena_alloc.dupe(u32, nums_list.items);
        var nums = buf;

        var valid = false;

        var remove: ?u32 = null;

        while (!valid) {
            if (remove) |remove_index| {
                if (remove_index == nums.len) {
                    continue :outer;
                }

                std.mem.copyForwards(u32, nums[remove_index..], nums[remove_index + 1 ..]);
                nums.len -= 1;
            }

            defer {
                if (remove) |remove_index| {
                    remove = remove_index + 1;
                } else {
                    remove = 0;
                }
                @memcpy(buf, nums_list.items);
                nums = buf;
            }

            var all_inc = true;
            var all_dec = true;
            var all_range = true;

            var i: usize = 0;

            while (i < nums.len - 1) : (i += 1) {
                const num = nums[i + 1];
                const prev_num = nums[i];

                const inc = num > prev_num;
                const dec = num < prev_num;

                const diff = @max(num, prev_num) - @min(num, prev_num);
                const range = diff == 1 or diff == 2 or diff == 3;

                all_inc = inc and all_inc;
                all_dec = dec and all_dec;
                all_range = range and all_range;
            }
            valid = (all_inc or all_dec) and all_range;
        }
        safe_count += @intFromBool(valid);
    }

    try stdout.print("safe count: {}\n", .{safe_count});

    try bw.flush(); // don't forget to flush!
}
