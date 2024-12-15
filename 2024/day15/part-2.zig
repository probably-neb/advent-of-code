const std = @import("std");

const input = @embedFile("./input.txt");

const Dir = enum {
    left,
    right,
    up,
    down,
};

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const board__moves = split_N_times_seq(u8, input, "\n\n", 2);

    const board = blk: {
        const board_base = board__moves[0];
        var count_nl: u32 = 0;
        for (board_base) |c| {
            if (c == '\n') {
                count_nl += 1;
            }
        }
        var board = try alloc.alloc(u8, board_base.len * 2 - count_nl);
        var i: u32 = 0;
        var bbi: u32 = 0;
        while (bbi < board_base.len) : (bbi += 1) {
            const chars: [2]u8 = switch (board_base[bbi]) {
                '@' => .{ '@', '.' },
                '.' => .{ '.', '.' },
                '#' => .{ '#', '#' },
                'O' => .{ '[', ']' },
                '\n' => {
                    board[i] = '\n';
                    i += 1;
                    continue;
                },
                else => unreachable,
            };
            defer i += 2;
            board[i] = chars[0];
            board[i + 1] = chars[1];
        }

        break :blk board;
    };

    const moves = board__moves[1];

    const C = Cursor.init_from_nl_grid(board);

    var arena = std.heap.ArenaAllocator.init(alloc);
    const arena_alloc = arena.allocator();

    const robot_start = Cursor.get_row_col(
        board,
        @intCast(std.mem.indexOfScalar(u8, board, '@') orelse unreachable),
    );

    var rpos = robot_start;

    for (moves) |move| {
        defer {
            _ = arena.reset(.retain_capacity);
        }
        defer if (board[C.at(rpos.row, rpos.col)] != '@') {
            const robot_loc = Cursor.get_row_col(
                board,
                @intCast(std.mem.indexOfScalar(u8, board, '@') orelse {
                    std.debug.panic("expected robot to be at {}, {} but it is nowhere to be found..\n", .{ rpos.row, rpos.col });
                }),
            );
            std.debug.panic("robot should be at {},{} but it is at {},{}\n", .{ rpos.row, rpos.col, robot_loc.row, robot_loc.col });
        };
        std.debug.print("board:\n{s}\n\nMove: {c}:\n", .{ board, move });

        switch (move) {
            '<' => {
                if (rpos.col == 0) {
                    continue;
                }
                rpos = move_robot(arena_alloc, board, C, .left, rpos.row, rpos.col);
            },
            '>' => {
                if (rpos.col == C.w - 1) {
                    continue;
                }
                rpos = move_robot(arena_alloc, board, C, .right, rpos.row, rpos.col);
            },
            '^' => {
                if (rpos.row == 0) {
                    continue;
                }
                rpos = move_robot(arena_alloc, board, C, .up, rpos.row, rpos.col);
            },
            'v' => {
                if (rpos.row == C.h - 1) {
                    continue;
                }
                rpos = move_robot(arena_alloc, board, C, .down, rpos.row, rpos.col);
            },
            '\n' => continue,
            else => unreachable,
        }
    }
    std.debug.print("board\n{s}\n", .{board});

    var gps: u32 = 0;
    for (0..C.h) |row| {
        for (0..C.w) |col| {
            if (board[C.at(@intCast(row), @intCast(col))] == '[') {
                gps += @intCast(100 * row + col);
            }
        }
    }

    std.debug.print("gps: {}\n", .{gps});
}

fn move_robot(alloc: std.mem.Allocator, board: []u8, C: Cursor, dir: Dir, start_row: Cursor.Index, start_col: Cursor.Index) Cursor.Loc {
    if (dir == .left or dir == .right) {
        var col = switch (dir) {
            .left => start_col - 1,
            .right => start_col + 1,
            else => unreachable,
        };
        while (switch (dir) {
            .left => col > 0,
            .right => col < C.w - 1,
            else => unreachable,
        } and board[C.at(start_row, col)] == '[' or board[C.at(start_row, col)] == ']') : (switch (dir) {
            .left => col -= 1,
            .right => col += 1,
            else => unreachable,
        }) {}
        switch (board[C.at(start_row, col)]) {
            '.' => {
                var board_row = C.get_row(u8, board, start_row);
                switch (dir) {
                    .left => {
                        std.mem.copyForwards(u8, board_row[col .. start_col - 1], board_row[col + 1 .. start_col]);
                        board[C.at(start_row, start_col)] = '.';
                        board[C.left(start_row, start_col)] = '@';
                        return .{
                            .row = start_row,
                            .col = start_col - 1,
                        };
                    },
                    .right => {
                        std.mem.copyBackwards(u8, board_row[start_col + 2 .. col + 1], board_row[start_col + 1 .. col]);
                        board[C.at(start_row, start_col)] = '.';
                        board[C.right(start_row, start_col)] = '@';
                        return .{
                            .row = start_row,
                            .col = start_col + 1,
                        };
                    },
                    else => unreachable,
                }
            },
            '#' => {
                // no move
                return .{
                    .row = start_row,
                    .col = start_col,
                };
            },
            else => {
                std.debug.panic("unexpected char: {c}\n", .{board[C.at(start_row, col)]});
                unreachable;
            },
        }
        unreachable;
    }

    // row + 0 - 1 == row - 1 :: up
    // row + 2 - 1 == row + 1 :: down
    const inc: u8 = switch (dir) {
        .up => 0,
        .down => 2,
        else => unreachable,
    };

    const next_row = start_row + inc - 1;
    var front = std.ArrayList(Cursor.Loc).init(alloc);
    defer front.deinit();

    switch (board[C.at(next_row, start_col)]) {
        '.' => {
            // std.debug.print("step in dir {s} from {}, {} is empty - proceeding to {}, {}\n", .{
            //     @tagName(dir),
            //     start_row,
            //     start_col,
            //     next_row,
            //     start_col,
            // });
            board[C.at(next_row, start_col)] = '@';
            board[C.at(start_row, start_col)] = '.';
            return .{
                .row = next_row,
                .col = start_col,
            };
        },
        '#' => return .{
            .row = start_row,
            .col = start_col,
        },
        '[' => {
            front.append(.{
                .row = next_row,
                .col = start_col,
            }) catch unreachable;
        },
        ']' => {
            front.append(.{
                .row = next_row,
                // col of corresponding '['
                .col = start_col - 1,
            }) catch unreachable;
        },
        else => unreachable,
    }

    const can_move = move_robot_up_down(alloc, board, C, inc, front.items) catch unreachable;
    if (can_move) {
        // FIXME: move robot here
        board[C.at(next_row, start_col)] = '@';
        board[C.at(start_row, start_col)] = '.';
        return .{
            .row = next_row,
            .col = start_col,
        };
    }
    return .{
        .row = start_row,
        .col = start_col,
    };
}

fn move_robot_up_down(alloc: std.mem.Allocator, board: []u8, C: Cursor, inc: u8, prev: []const Cursor.Loc) !bool {
    if (prev.len == 0) {
        return true;
    }
    var front = try std.ArrayList(Cursor.Loc).initCapacity(alloc, prev.len * 2);
    defer front.deinit();

    for (prev) |prev_loc| {
        const prev_row = prev_loc.row;
        const prev_col = prev_loc.col;
        const next_row = prev_row + inc - 1;
        switch (board[C.at(next_row, prev_col)]) {
            '.' => {},
            '#' => return false, // hit blocker
            '[' => {
                front.appendAssumeCapacity(.{
                    .row = next_row,
                    .col = prev_col,
                });
                // don't double add
                continue;
            },
            ']' => {
                front.appendAssumeCapacity(.{
                    .row = next_row,
                    .col = prev_col - 1,
                });
            },
            else => unreachable,
        }
        switch (board[C.at(next_row, prev_col + 1)]) {
            '.' => {},
            '#' => return false,
            '[' => {
                front.appendAssumeCapacity(.{
                    .row = next_row,
                    .col = prev_col + 1,
                });
            },
            ']' => unreachable,
            else => unreachable,
        }
    }

    const next_front_unblocked = try move_robot_up_down(alloc, board, C, inc, front.items);
    if (!next_front_unblocked) {
        return false;
    }

    for (prev) |prev_loc| {
        const prev_row = prev_loc.row;
        const prev_col = prev_loc.col;
        const next_row = prev_row + inc - 1;
        board[C.at(next_row, prev_col)] = '[';
        board[C.at(next_row, prev_col + 1)] = ']';

        board[C.at(prev_row, prev_col)] = '.';
        board[C.at(prev_row, prev_col + 1)] = '.';
    }

    return true;
}

fn split_N_times(comptime T: type, buf: []const T, needle: T, comptime N: comptime_int) [N][]const T {
    var elems: [N][]const T = undefined;
    var iter = std.mem.tokenizeScalar(T, buf, needle);
    inline for (0..N) |i| {
        elems[i] = iter.next() orelse std.debug.panic("Not Enough Segments in Buf. Failed to split N ({}) times", .{N});
    }
    if (iter.next()) |_| {
        std.debug.panic("Too Many Segments in Buf. Failed to split N ({}) times", .{N});
    }
    return elems;
}

fn split_N_times_seq(comptime T: type, buf: []const T, needle: []const T, comptime N: comptime_int) [N][]const T {
    var elems: [N][]const T = undefined;
    var iter = std.mem.tokenizeSequence(T, buf, needle);
    inline for (0..N) |i| {
        elems[i] = iter.next() orelse std.debug.panic("Not Enough Segments in Buf. Failed to split N ({}) times", .{N});
    }
    if (iter.next()) |_| {
        std.debug.panic("Too Many Segments in Buf. Failed to split N ({}) times", .{N});
    }
    return elems;
}

fn strip_prefix_exact(comptime T: type, buf: []const T, prefix: []const T) []const T {
    std.debug.assert(buf.len > prefix.len);
    std.debug.assert(std.mem.eql(T, buf[0..prefix.len], prefix));
    return buf[prefix.len..];
}

const Cursor = struct {
    w: Index,
    h: Index,

    const Index = u32;

    const Loc = struct {
        row: Index,
        col: Index,
    };

    pub fn init_from_nl_grid(in: []const u8) Cursor {
        std.debug.assert(in.len == 0 or !std.ascii.isWhitespace(in[0]));
        const trimmed = std.mem.trim(u8, in, &std.ascii.whitespace);
        const w: u32 = @intCast(std.mem.indexOfScalar(u8, trimmed, '\n') orelse 0);
        const h: u32 = @intCast(std.mem.count(u8, trimmed, "\n") + 1);
        return .{
            .w = w,
            .h = h,
        };
    }

    pub fn valid_dirs(self: Cursor, row: Index, col: Index) struct { l: ?Index, r: ?Index, u: ?Index, d: ?Index } {
        const V = @Vector(4, u32);
        const loc = V{ 0, col, 0, row };
        const cmp = V{ col, self.w -| 1, row, self.h -| 1 };
        const res = loc < cmp;
        return .{
            .l = if (res[0]) self.left(row, col) else null,
            .r = if (res[1]) self.right(row, col) else null,
            .u = if (res[2]) self.up(row, col) else null,
            .d = if (res[3]) self.down(row, col) else null,
        };
    }

    pub fn at(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(row < self.h);
        std.debug.assert(col < self.w);
        return (row * self.w) + row + col;
    }

    pub fn get_row(self: Cursor, comptime T: type, in: []T, row: Index) []T {
        const start = self.at(row, 0);
        const end = self.at(row, self.w - 1);
        return in[start..end];
    }

    pub fn get_row_col(in: []const u8, idx: Index) Loc {
        var col: Index = 0;
        var row: Index = 0;
        for (in, 0..) |c, index| {
            if (index == idx) {
                break;
            }
            if (c == '\n') {
                row += 1;
                col = 0;
            } else {
                col += 1;
            }
        }
        return .{
            .row = row,
            .col = col,
        };
    }

    pub fn left(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(col > 0);
        return self.at(row, col - 1);
    }
    pub fn right(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(col < self.w - 1);
        return self.at(row, col + 1);
    }
    pub fn up(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(row > 0);
        return self.at(row - 1, col);
    }
    pub fn down(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(row < self.h - 1);
        return self.at(row + 1, col);
    }

    pub fn up_left(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(col > 0);
        std.debug.assert(row > 0);
        return self.at(row - 1, col - 1);
    }
    pub fn up_right(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(row > 0);
        std.debug.assert(col < self.w - 1);
        return self.at(row - 1, col + 1);
    }
    pub fn down_left(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(col > 0);
        std.debug.assert(row < self.h - 1);
        return self.at(row + 1, col - 1);
    }
    pub fn down_right(self: Cursor, row: Index, col: Index) Index {
        std.debug.assert(col < self.w - 1);
        std.debug.assert(row < self.h - 1);
        return self.at(row + 1, col + 1);
    }
};

test Cursor {
    var C: Cursor = undefined;

    C = Cursor.init_from_nl_grid("AB\nCD\n");
    try std.testing.expectEqual(2, C.h);
    try std.testing.expectEqual(2, C.w);
    try std.testing.expectEqual(0, C.at(0, 0));
    try std.testing.expectEqual(4, C.at(1, 1));

    C = Cursor.init_from_nl_grid("ABC\nCDE");
    try std.testing.expectEqual(2, C.h);
    try std.testing.expectEqual(3, C.w);
    try std.testing.expectEqual(4, C.at(1, 0));
    try std.testing.expectEqual(6, C.at(1, 2));
}
