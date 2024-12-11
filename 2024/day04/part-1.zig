const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var count: usize = 0;

    var lines_list = std.ArrayList([]const u8).init(alloc);
    // rows
    {
        var seqs = std.ArrayList([]const u8).init(alloc);
        defer seqs.deinit();
        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            try seqs.append(line);
            try lines_list.append(line);
            try stdout.print("{s}\n", .{line});
        }
        count += try check_all(alloc, seqs.items);
    }

    const lines = lines_list.items;
    const line_width = lines[0].len;

    // cols
    {
        var seqs = std.ArrayList([]const u8).init(alloc);
        defer seqs.deinit();
        for (0..line_width) |col| {
            const cols = try alloc.alloc(u8, line_width);
            for (lines, 0..) |line, row| {
                cols[row] = line[col];
            }
            try seqs.append(cols);
        }
        count += try check_all(alloc, seqs.items);
    }

    // diagonals like \
    {
        var seqs = std.ArrayList([]const u8).init(alloc);
        defer seqs.deinit();
        try stdout.print("diagonals like \\ \n", .{});
        for (0..lines.len) |starting_row| {
            for (0..line_width) |starting_col| {
                if (starting_row > 0 and starting_col > 0) {
                    continue;
                }
                const seq = try alloc.alloc(u8, line_width - starting_col);
                for (starting_col..line_width, starting_row..) |col, row| {
                    if (row >= lines.len or col >= line_width) {
                        break;
                    }
                    seq[row] = lines[row][col];
                }
                try seqs.append(seq);
                try stdout.print("{s}\n", .{seq});
            }
        }
        count += try check_all(alloc, seqs.items);
    }

    // diagonals like /
    {
        var seqs = std.ArrayList([]const u8).init(alloc);
        defer seqs.deinit();

        try stdout.print("diagonals like /\n", .{});
        for (0..lines.len) |starting_row| {
            for (0..line_width) |starting_col| {
                if (starting_row > 0 and starting_col < line_width - 1) {
                    continue;
                }
                const seq = try alloc.alloc(u8, starting_col + 1);
                for (0..starting_col + 1, starting_row..) |col, row| {
                    if (row >= lines.len or col >= line_width) {
                        break;
                    }
                    seq[row] = lines[row][starting_col - col];
                }
                try seqs.append(seq);
                try stdout.print("{s}\n", .{seq});
            }
        }
        count += try check_all(alloc, seqs.items);
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

fn check_all(alloc: std.mem.Allocator, seqs: [][]const u8) !usize {
    var count: usize = 0;
    for (seqs) |seq| {
        // try stdout.print("{s}\n", .{seq});
        var i: usize = 0;
        while (std.mem.indexOfPos(u8, seq, i, "XMAS")) |idx| {
            i = idx + 1;
            count += 1;
        }

        const seq_rev = try alloc.dupe(u8, seq);
        defer alloc.free(seq_rev);
        std.mem.reverse(u8, seq_rev);

        i = 0;
        while (std.mem.indexOfPos(u8, seq_rev, i, "XMAS")) |idx| {
            i = idx + 1;
            count += 1;
        }
    }
    return count;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
