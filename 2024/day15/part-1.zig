const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const board__moves = split_N_times_seq(u8, input, "\n\n", 2);
    var board = alloc.dupe(u8, board__moves[0]) catch unreachable;
    const moves = board__moves[1];

    const C = Cursor.init_from_nl_grid(board);

    const robot_start = Cursor.get_row_col(
        board,
        @intCast(std.mem.indexOfScalar(u8, board, '@') orelse unreachable),
    );

    var rpos = robot_start;

    for (moves) |move| {
        std.debug.print("board:\n{s}\n\nMove: {c}:\n", .{ board, move });
        var robo_move: ?enum {
            left,
            right,
            up,
            down,
        } = null;
        defer if (robo_move) |rmove| {
            board[C.at(rpos.row, rpos.col)] = '.';
            switch (rmove) {
                .left => rpos.col -= 1,
                .right => rpos.col += 1,
                .up => rpos.row -= 1,
                .down => rpos.row += 1,
            }
            board[C.at(rpos.row, rpos.col)] = '@';
        };

        switch (move) {
            '<' => {
                if (rpos.col == 0) {
                    continue;
                }
                switch (board[C.left(rpos.row, rpos.col)]) {
                    '#' => continue,
                    '.' => {
                        robo_move = .left;
                        continue;
                    },
                    'O' => {
                        var col = rpos.col - 1;
                        while (col > 0 and board[C.at(rpos.row, col)] == 'O') : (col -= 1) {}
                        switch (board[C.at(rpos.row, col)]) {
                            '.' => {
                                board[C.at(rpos.row, col)] = 'O';
                                board[C.left(rpos.row, rpos.col)] = '.';
                                robo_move = .left;
                            },
                            '#' => continue,
                            else => unreachable,
                        }
                    },
                    else => unreachable,
                }
            },
            '>' => {
                if (rpos.col == C.w - 1) {
                    continue;
                }

                switch (board[C.right(rpos.row, rpos.col)]) {
                    '#' => continue,
                    '.' => {
                        robo_move = .right;
                        continue;
                    },
                    'O' => {
                        var col = rpos.col + 1;
                        while (col < C.w - 1 and board[C.at(rpos.row, col)] == 'O') : (col += 1) {}
                        switch (board[C.at(rpos.row, col)]) {
                            '.' => {
                                board[C.at(rpos.row, col)] = 'O';
                                board[C.right(rpos.row, rpos.col)] = '.';
                                robo_move = .right;
                            },
                            '#' => continue,
                            else => unreachable,
                        }
                    },
                    else => unreachable,
                }
            },
            '^' => {
                if (rpos.row == 0) {
                    continue;
                }
                switch (board[C.up(rpos.row, rpos.col)]) {
                    '#' => continue,
                    '.' => {
                        robo_move = .up;
                        continue;
                    },
                    'O' => {
                        var row = rpos.row - 1;
                        while (row > 0 and board[C.at(row, rpos.col)] == 'O') : (row -= 1) {}
                        switch (board[C.at(row, rpos.col)]) {
                            '.' => {
                                board[C.at(row, rpos.col)] = 'O';
                                board[C.up(rpos.row, rpos.col)] = '.';
                                robo_move = .up;
                            },
                            '#' => continue,
                            else => {
                                std.debug.panic("unexpected char: {c}\n", .{board[C.at(row, rpos.col)]});
                                unreachable;
                            },
                        }
                    },
                    else => unreachable,
                }
            },
            'v' => {
                if (rpos.row == C.h - 1) {
                    continue;
                }

                switch (board[C.down(rpos.row, rpos.col)]) {
                    '#' => continue,
                    '.' => {
                        robo_move = .down;
                        continue;
                    },
                    'O' => {
                        var row = rpos.row + 1;
                        while (row < C.h - 1 and board[C.at(row, rpos.col)] == 'O') : (row += 1) {}
                        switch (board[C.at(row, rpos.col)]) {
                            '.' => {
                                board[C.at(row, rpos.col)] = 'O';
                                board[C.down(rpos.row, rpos.col)] = '.';
                                robo_move = .down;
                            },
                            '#' => continue,
                            else => {
                                std.debug.panic("unexpected char: {c}\n", .{board[C.at(row, rpos.col)]});
                                unreachable;
                            },
                        }
                    },
                    else => unreachable,
                }
            },
            '\n' => continue,
            else => unreachable,
        }
    }
    std.debug.print("board\n{s}\n", .{board});

    var gps: u32 = 0;
    for (0..C.h) |row| {
        for (0..C.w) |col| {
            if (board[C.at(@intCast(row), @intCast(col))] == 'O') {
                gps += @intCast(100 * row + col);
            }
        }
    }

    std.debug.print("gps: {}\n", .{gps});
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

    pub fn get_row_col(in: []const u8, idx: Index) struct { row: Index, col: Index } {
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
