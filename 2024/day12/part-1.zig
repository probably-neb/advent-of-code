const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    const C = Cursor.init_from_nl_grid(input);
    std.debug.print("h: {} w: {}\n", .{ C.h, C.w });

    var visited = try alloc.alloc(bool, input.len);
    @memset(visited, false);

    var info_map = std.AutoHashMap(u32, struct { plant: u8, perim: u32, area: u32 }).init(alloc);

    var queue = std.ArrayList(struct { row: u32, col: u32 }).init(alloc);

    for (0..C.h) |_row| {
        const row: u32 = @intCast(_row);
        for (0..C.w) |_col| {
            const col: u32 = @intCast(_col);
            const loc = C.at(row, col);
            if (visited[loc]) {
                continue;
            }
            const plant = input[loc];
            const entry = try info_map.getOrPut(loc);
            std.debug.assert(!entry.found_existing);

            entry.value_ptr.* = .{
                .plant = plant,
                .perim = 0,
                .area = 0,
            };

            var info_ptr = entry.value_ptr;

            std.debug.assert(queue.items.len == 0);
            try queue.append(.{ .row = row, .col = col });

            while (queue.popOrNull()) |q_point| {
                const q_row = q_point.row;
                const q_col = q_point.col;
                const q_loc = C.at(q_row, q_col);

                if (visited[q_loc]) {
                    continue;
                }

                info_ptr.area += 1;
                visited[q_loc] = true;

                // defer {
                //     print_board(stdout, C, input, visited) catch unreachable;
                //     bw.flush() catch unreachable;
                // }

                const dirs = C.valid_dirs(q_row, q_col);
                if (dirs.l) |left| {
                    if (input[left] != plant) {
                        info_ptr.perim += 1;
                    } else if (!visited[left]) {
                        try queue.append(.{ .row = q_row, .col = q_col - 1 });
                    }
                } else {
                    info_ptr.perim += 1;
                }
                if (dirs.r) |right| {
                    if (input[right] != plant) {
                        info_ptr.perim += 1;
                    } else if (!visited[right]) {
                        try queue.append(.{ .row = q_row, .col = q_col + 1 });
                    }
                } else {
                    info_ptr.perim += 1;
                }
                if (dirs.u) |up| {
                    if (input[up] != plant) {
                        info_ptr.perim += 1;
                    } else if (!visited[up]) {
                        try queue.append(.{ .row = q_row - 1, .col = q_col });
                    }
                } else {
                    info_ptr.perim += 1;
                }
                if (dirs.d) |down| {
                    if (input[down] != plant) {
                        info_ptr.perim += 1;
                    } else if (!visited[down]) {
                        try queue.append(.{ .row = q_row + 1, .col = q_col });
                    }
                } else {
                    info_ptr.perim += 1;
                }
            }
        }
    }

    var price: usize = 0;
    var regions_iter = info_map.valueIterator();

    while (regions_iter.next()) |region| {
        price += @intCast(region.area * region.perim);
    }

    try stdout.print("price: {}\n", .{price});

    try bw.flush();
}

fn print_board(writer: anytype, C: Cursor, in: []const u8, visited: []const bool) !void {
    for (0..C.h) |row| {
        for (0..C.w) |col| {
            const loc = C.at(@intCast(row), @intCast(col));
            if (visited[loc]) {
                try writer.writeByte(in[loc]);
            } else {
                try writer.writeByte('.');
            }
        }
        try writer.writeByte('\n');
    }
    try writer.writeByte('\n');
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
