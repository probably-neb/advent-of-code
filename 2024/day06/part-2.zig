const std = @import("std");

const input = @embedFile("./input.txt");

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

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

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

    const path_locs = blk: {
        var path_locs = std.ArrayList(Point).init(alloc);

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

        for (0..h) |r| {
            for (0..w) |c| {
                if (grid[r][c] == .guard) {
                    try path_locs.append(.{ .x = @intCast(c), .y = @intCast(r) });
                }
            }
        }

        for (grid) |gr| {
            for (gr) |*gc| {
                if (gc.* == .guard) {
                    gc.* = .empty;
                }
            }
        }

        break :blk path_locs.items;
    };

    try stdout.print("path_locs: {}\n", .{path_locs.len});
    try bw.flush();

    var visited_list = std.ArrayList([][2]?Dir).init(alloc);

    for (0..h) |_| {
        const v_row = try alloc.alloc([2]?Dir, w);
        @memset(v_row, .{ null, null });
        try visited_list.append(v_row);
    }

    var possible_locs = std.ArrayList(Point).init(alloc);

    var visited = visited_list.items;

    for (path_locs, 0..) |changed_loc, iter| {
        const r = changed_loc.y;
        const c = changed_loc.x;
        if (grid[r][c] == .block) {
            continue;
        }
        grid[r][c] = .block;

        defer {
            grid[r][c] = .empty;
            for (grid) |gr| {
                for (gr) |*gc| {
                    if (gc.* == .guard) {
                        gc.* = .empty;
                    }
                }
            }

            for (visited) |v_row| {
                @memset(v_row, .{ null, null });
            }
        }

        // if (iter == 417) {
        //     std.debug.print("{any}\n", .{changed_loc});
        //     // try print_board(stdout, grid, visited);
        //     // try stdout.print("{s}\n", .{"-" ** 20});
        //     try bw.flush();
        // }

        var guard_dir: Dir = .up;
        var guard_pos: Point = guard_start;

        var timer = try std.time.Timer.start();
        var iter_count: u32 = 0;
        check: while (true) {
            iter_count += 1;
            grid[guard_pos.y][guard_pos.x] = .guard;
            // const init_guard_pos = guard_pos;
            switch (guard_dir) {
                .up => {
                    if (guard_pos.y == 0) {
                        break :check;
                    }
                    if (grid[guard_pos.y - 1][guard_pos.x] == .block) {
                        guard_dir = .right;
                        var visit = &visited[guard_pos.y][guard_pos.x];
                        if (visit[0] == guard_dir or visit[1] == guard_dir) {
                            try possible_locs.append(changed_loc);
                            break :check;
                        }
                        if (visit[0] == null) {
                            visit[0] = guard_dir;
                        } else if (visit[1] == null) {
                            visit[1] = guard_dir;
                        } else {
                            // dead end
                            break :check;
                        }
                    } else {
                        guard_pos.y -= 1;
                    }
                },
                .down => {
                    if (guard_pos.y == h - 1) {
                        break :check;
                    }
                    if (grid[guard_pos.y + 1][guard_pos.x] == .block) {
                        guard_dir = .left;

                        var visit = &visited[guard_pos.y][guard_pos.x];
                        if (visit[0] == guard_dir or visit[1] == guard_dir) {
                            try possible_locs.append(changed_loc);
                            break :check;
                        }
                        if (visit[0] == null) {
                            visit[0] = guard_dir;
                        } else if (visit[1] == null) {
                            visit[1] = guard_dir;
                        } else {
                            // dead end
                            break :check;
                        }
                    } else {
                        guard_pos.y += 1;
                    }
                },
                .left => {
                    if (guard_pos.x == 0) {
                        break :check;
                    }
                    if (grid[guard_pos.y][guard_pos.x - 1] == .block) {
                        guard_dir = .up;

                        var visit = &visited[guard_pos.y][guard_pos.x];
                        if (visit[0] == guard_dir or visit[1] == guard_dir) {
                            try possible_locs.append(changed_loc);
                            break :check;
                        }
                        if (visit[0] == null) {
                            visit[0] = guard_dir;
                        } else if (visit[1] == null) {
                            visit[1] = guard_dir;
                        } else {
                            // dead end
                            break :check;
                        }
                    } else {
                        guard_pos.x -= 1;
                    }
                },
                .right => {
                    if (guard_pos.x == w - 1) {
                        break :check;
                    }
                    if (grid[guard_pos.y][guard_pos.x + 1] == .block) {
                        guard_dir = .down;

                        var visit = &visited[guard_pos.y][guard_pos.x];
                        if (visit[0] == guard_dir or visit[1] == guard_dir) {
                            try possible_locs.append(changed_loc);
                            break :check;
                        }
                        if (visit[0] == null) {
                            visit[0] = guard_dir;
                        } else if (visit[1] == null) {
                            visit[1] = guard_dir;
                        } else {
                            // dead end
                            break :check;
                        }
                    } else {
                        guard_pos.x += 1;
                    }
                },
            }
        }
        const time = timer.read();
        try stdout.print("\r{}/{} - {}", .{ iter + 1, path_locs.len, time });
        try bw.flush();
        // print_board(stdout, grid, visited);
    }
    std.debug.print("\n", .{});

    // print_board(stdout, grid, visited);

    const count = possible_locs.items.len;

    try stdout.print("count: {}\n", .{count});

    try bw.flush(); // don't forget to flush!
}

fn print_board(stdout: anytype, grid: []const []const State, visited: []const []const [2]?Dir) !void {
    for (0..grid.len) |row| {
        for (0..grid[0].len) |col| {
            if (visited[row][col][0]) |dir| {
                if (visited[row][col][1]) |_| {
                    try stdout.writeAll("+");
                } else if (dir == .up or dir == .down) {
                    try stdout.writeAll("|");
                } else {
                    try stdout.writeAll("-");
                }
            } else if (grid[row][col] == .block) {
                try stdout.writeAll("#");
            } else {
                try stdout.writeAll(".");
            }
        }
    }
}
