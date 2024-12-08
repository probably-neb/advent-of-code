const std = @import("std");

const input = @embedFile("./input.txt");

const Cell = union(enum) {
    freq: u8,
    anti: void,
    none: void,
};

const Point = struct {
    x: isize,
    y: isize,
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var board_list = std.ArrayList([]Cell).init(alloc);
    var freqs_map = std.AutoArrayHashMap(u8, std.ArrayList(Point)).init(alloc);

    var w: usize = 0;
    var h: usize = 0;

    var line_iter = std.mem.tokenize(u8, input, "\n");
    var l_row: usize = 0;
    while (line_iter.next()) |line| : (l_row += 1) {
        w = line.len;
        h += 1;

        const row = try alloc.alloc(Cell, w);

        for (line, row, 0..) |ch, *c, l_col| {
            switch (ch) {
                '#', '.' => c.* = Cell{ .none = {} },
                else => {
                    c.* = Cell{ .freq = ch };
                    var entry = try freqs_map.getOrPut(ch);
                    if (!entry.found_existing) {
                        entry.value_ptr.* = std.ArrayList(Point).init(alloc);
                    }
                    try entry.value_ptr.append(Point{ .x = @intCast(l_col), .y = @intCast(l_row) });
                },
            }
        }
        try board_list.append(row);
    }

    const board = board_list.items;

    try print_board(stdout, board_list.items);
    {
        var entries_iter = freqs_map.iterator();
        while (entries_iter.next()) |entry| {
            try stdout.print("{c}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.*.items });
        }
    }
    try bw.flush();

    var entries_iter = freqs_map.iterator();
    while (entries_iter.next()) |entry| {
        const points = entry.value_ptr.*.items;
        for (points, 0..) |a, a_index| {
            for (points[a_index + 1 ..]) |b| {
                const dx: isize = b.x - a.x;
                const dy: isize = b.y - a.y;
                std.debug.print("dx: {}, dy: {}\n", .{ dx, dy });

                var x = a;
                while (x.x - dx >= 0 and x.y - dy >= 0) {
                    x.x -= dx;
                    x.y -= dy;
                }
                std.debug.print("line start: {any}\n", .{x});

                while (!((x.x < 0 or x.x >= w) and (x.y < 0 or x.y >= h))) : ({
                    x.x += dx;
                    x.y += dy;
                }) {
                    std.debug.print("checking {} {}\n", .{ x.x, x.y });
                    if (x.x < 0 or x.y < 0 or x.x >= w or x.y >= h) {
                        std.debug.print("oob: skipping {} {}\n", .{ x.x, x.y });
                        continue;
                    }
                    const is_x_a = x.x == a.x and x.y == b.y;
                    const is_x_b = x.x == b.x and x.y == a.y;
                    // const is_x_empty = board[@intCast(x.y)][@intCast(x.x)] == .none;
                    if (is_x_a or is_x_b) {
                        std.debug.print("skipping {} {}\n", .{ x.x, x.y });
                        continue;
                    }
                    const dist_a_x = distance(a, x);
                    const dist_b_x = distance(b, x);
                    const is_double = (dist_a_x * 2 == dist_b_x) or (dist_b_x * 2 == dist_a_x);
                    std.debug.print("dist_a_x: {}, dist_b_x: {}, is_double: {}\n", .{ dist_a_x, dist_b_x, is_double });
                    if (is_double) {
                        board[@intCast(x.y)][@intCast(x.x)] = Cell{ .anti = {} };
                    }
                }
            }
        }
    }

    try print_board(stdout, board_list.items);
    var count: usize = 0;

    for (board) |row| {
        for (row) |cell| {
            if (cell == .anti) {
                count += 1;
            }
        }
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

fn print_board(writer: anytype, board: []const []const Cell) !void {
    const w = board[0].len;
    const h = board.len;
    for (0..h) |row| {
        for (0..w) |col| {
            const ch = switch (board[row][col]) {
                .freq => |freq| freq,
                .none => '.',
                .anti => '#',
            };

            try writer.print("{c}", .{ch});
        }
        try writer.print("\n", .{});
    }
}

// points a, b
// dist(a, x) * 2 == dist(x, b);

fn distance(a: Point, b: Point) f64 {
    const dx: f64 = @floatFromInt(@abs(a.x - b.x));
    const dy: f64 = @floatFromInt(@abs(a.y - b.y));

    return std.math.sqrt(dx * dx + dy * dy);
}

test distance {
    try std.testing.expectEqual(0, distance(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = 0 }));
    try std.testing.expectEqual(2, distance(.{ .x = 0, .y = 0 }, .{ .x = 2, .y = 0 }));
    try std.testing.expectEqual(2, distance(.{ .x = 0, .y = 0 }, .{ .x = 0, .y = 2 }));
}
