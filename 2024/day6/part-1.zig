const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    const State = enum {
        block,
        guard,
        empty,
    };

    const Dir = enum { up, down, left, right };

    const Point = struct {
        x: u32,
        y: u32,
    };

    var board = std.ArrayList([]State).init(alloc);

    var w: usize = 0;
    var h: usize = 0;

    var guard_start: Point = undefined;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var row: u32 = 0;
    while (line_iter.next()) |line| : ({
        row += 1;
        h += 1;
    }) {
        w = line.len;
        const board_row = try alloc.alloc(State, w);

        for (line, board_row, 0..) |c, *r, col| {
            r.* = switch (c) {
                '#' => .block,
                '^' => blk: {
                    guard_start = .{ .x = @intCast(col), .y = row };
                    break :blk .empty;
                },
                else => .empty,
            };
        }
        try board.append(board_row);
    }

    var grid = board.items;

    var guard_dir: Dir = .up;
    var guard_pos: Point = guard_start;

    var done = false;

    while (!done) {
        grid[guard_pos.y][guard_pos.x] = .guard;
        switch (guard_dir) {
            .up => {
                if (guard_pos.y == 0) {
                    done = true;
                    break;
                }
                if (grid[guard_pos.y - 1][guard_pos.x] == .block) {
                    guard_dir = .right;
                } else {
                    guard_pos.y -= 1;
                }
            },
            .down => {
                if (guard_pos.y == h - 1) {
                    done = true;
                    break;
                }
                if (grid[guard_pos.y + 1][guard_pos.x] == .block) {
                    guard_dir = .left;
                } else {
                    guard_pos.y += 1;
                }
            },
            .left => {
                if (guard_pos.x == 0) {
                    done = true;
                    break;
                }
                if (grid[guard_pos.y][guard_pos.x - 1] == .block) {
                    guard_dir = .up;
                } else {
                    guard_pos.x -= 1;
                }
            },
            .right => {
                if (guard_pos.x == w - 1) {
                    done = true;
                    break;
                }
                if (grid[guard_pos.y][guard_pos.x + 1] == .block) {
                    guard_dir = .down;
                } else {
                    guard_pos.x += 1;
                }
            },
        }
    }

    var count: u32 = 0;

    for (grid) |r| {
        for (r) |c| {
            if (c == .guard) {
                count += 1;
            }
        }
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}
