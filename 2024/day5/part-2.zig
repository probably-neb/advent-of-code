const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var sec_iter = std.mem.tokenizeSequence(u8, input, "\n\n");
    const section_one = sec_iter.next().?;
    const section_two = sec_iter.next().?;

    var rules = std.AutoArrayHashMap(u32, std.ArrayList(u32)).init(alloc);

    var rules_iter = std.mem.tokenizeScalar(u8, section_one, '\n');

    while (rules_iter.next()) |rule| {
        const bar_idx = std.mem.indexOfScalar(u8, rule, '|').?;
        const befor = try std.fmt.parseUnsigned(u32, rule[0..bar_idx], 10);
        const after = try std.fmt.parseUnsigned(u32, rule[bar_idx + 1 ..], 10);

        const entry = try rules.getOrPut(befor);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(u32).init(alloc);
        }
        try entry.value_ptr.append(after);
    }

    var middle_page_num_sum: usize = 0;

    var orderings_iter = std.mem.tokenizeScalar(u8, section_two, '\n');

    var ordering = std.ArrayList(u32).init(alloc);

    while (orderings_iter.next()) |ordering_str| {
        defer ordering.clearRetainingCapacity();
        var page_iter = std.mem.tokenizeScalar(u8, ordering_str, ',');

        while (page_iter.next()) |page| {
            try ordering.append(try std.fmt.parseUnsigned(u32, page, 10));
        }

        var ok: bool = false;
        var fixed: bool = false;
        while (!ok) {
            ok = blk: for (ordering.items, 0..) |page, i| {
                const entry = rules.get(page);
                if (entry == null) {
                    continue;
                }
                const up_to_page = ordering.items[0..i];
                const not_allowed_before_pages = entry.?.items;

                for (not_allowed_before_pages) |not_allowed_before_page| {
                    if (std.mem.indexOfScalar(u32, up_to_page, not_allowed_before_page)) |index| {
                        fixed = true;
                        _ = ordering.orderedRemove(index);
                        try ordering.insert(i, not_allowed_before_page);
                        break :blk false;
                    }
                }
            } else true;
        }

        if (fixed) {
            const middle_page = ordering.items[@divFloor(ordering.items.len, 2)];
            middle_page_num_sum += middle_page;
        }
    }

    try stdout.print("sum: {}\n", .{middle_page_num_sum});

    try bw.flush(); // don't forget to flush!
}

fn split_once(buf: []const u8, splitter: u8) ?[]const u8 {
    const index = std.mem.indexOfScalar(u8, buf, splitter) orelse return null;
    return buf[0..index];
}
