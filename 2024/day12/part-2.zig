const std = @import("std");

const input = @embedFile("./input.txt");

const Edges = struct {
    l: bool,
    r: bool,
    u: bool,
    d: bool,

    const Field = std.meta.FieldEnum(@This());

    fn any(self: @This()) bool {
        const vals: @Vector(4, bool) = .{ self.l, self.r, self.u, self.d };
        return @reduce(.Or, vals);
    }

    fn any_but(self: @This(), field: Field) bool {
        var vals: @Vector(4, bool) = .{ self.l, self.r, self.u, self.d };
        vals[@intFromEnum(field)] = false;
        return @reduce(.Or, vals);
    }
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    const C = Cursor.init_from_nl_grid(input);
    std.debug.print("h: {} w: {}\n", .{ C.h, C.w });

    var visited = try alloc.alloc(bool, input.len);
    @memset(visited, false);

    var edges = try alloc.alloc(Edges, input.len);
    @memset(edges, .{ .l = false, .r = false, .u = false, .d = false });

    var info_map = std.AutoHashMap(u32, struct { plant: u8, edges: u32, area: u32 }).init(alloc);

    var queue = std.ArrayList(struct { row: u32, col: u32 }).init(alloc);
    var region_queue = std.ArrayList(struct { row: u32, col: u32 }).init(alloc);

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
                .edges = 0,
                .area = 0,
            };

            var info_ptr = entry.value_ptr;

            std.debug.assert(queue.items.len == 0);

            try queue.append(.{ .row = row, .col = col });

            defer @memset(edges, .{ .l = false, .r = false, .u = false, .d = false });

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
                        edges[q_loc].l = true;
                    } else if (!visited[left]) {
                        try queue.append(.{ .row = q_row, .col = q_col - 1 });
                    }
                } else {
                    edges[q_loc].l = true;
                }
                if (dirs.r) |right| {
                    if (input[right] != plant) {
                        edges[q_loc].r = true;
                    } else if (!visited[right]) {
                        try queue.append(.{ .row = q_row, .col = q_col + 1 });
                    }
                } else {
                    edges[q_loc].r = true;
                }
                if (dirs.u) |up| {
                    if (input[up] != plant) {
                        edges[q_loc].u = true;
                    } else if (!visited[up]) {
                        try queue.append(.{ .row = q_row - 1, .col = q_col });
                    }
                } else {
                    edges[q_loc].u = true;
                }
                if (dirs.d) |down| {
                    if (input[down] != plant) {
                        edges[q_loc].d = true;
                    } else if (!visited[down]) {
                        try queue.append(.{ .row = q_row + 1, .col = q_col });
                    }
                } else {
                    edges[q_loc].d = true;
                }
                if (edges[q_loc].any()) {
                    try region_queue.append(.{ .row = q_row, .col = q_col });
                }
            }

            while (region_queue.popOrNull()) |q_point| {
                const q_row = q_point.row;
                const q_col = q_point.col;
                const q_loc = C.at(q_row, q_col);

                if (!edges[q_loc].any()) {
                    continue;
                }

                const q_edges = edges[q_loc];

                const dbg = false;
                if (dbg) {
                    print_edges(stdout, C, edges) catch unreachable;
                    bw.flush() catch unreachable;
                }
                if (q_edges.l) {
                    defer if (dbg) {
                        print_edges(stdout, C, edges) catch unreachable;
                        bw.flush() catch unreachable;
                    };
                    info_ptr.edges += 1;
                    var offset: u32 = 0;
                    var tmp_loc = C.at(q_row, q_col);
                    while (edges[tmp_loc].l) {
                        edges[tmp_loc].l = false;
                        if (offset == q_row) break;
                        offset += 1;
                        tmp_loc = C.at(q_row - offset, q_col);
                    }
                    tmp_loc = C.at(q_row, q_col);
                    offset = 0;
                    edges[tmp_loc].l = true;
                    while (edges[tmp_loc].l) {
                        edges[tmp_loc].l = false;
                        offset += 1;
                        if (offset + q_row == C.h) break;
                        tmp_loc = C.at(q_row + offset, q_col);
                    }
                }

                if (q_edges.r) {
                    defer if (dbg) {
                        print_edges(stdout, C, edges) catch unreachable;
                        bw.flush() catch unreachable;
                    };
                    info_ptr.edges += 1;
                    var offset: u32 = 0;
                    var tmp_loc = C.at(q_row, q_col);
                    while (edges[tmp_loc].r) {
                        edges[tmp_loc].r = false;
                        if (offset == q_row) break;
                        offset += 1;
                        tmp_loc = C.at(q_row - offset, q_col);
                    }
                    tmp_loc = C.at(q_row, q_col);
                    offset = 0;
                    edges[tmp_loc].r = true;
                    while (edges[tmp_loc].r) {
                        edges[tmp_loc].r = false;
                        offset += 1;
                        if (offset + q_row == C.h) break;
                        tmp_loc = C.at(q_row + offset, q_col);
                    }
                }

                if (q_edges.u) {
                    defer if (dbg) {
                        print_edges(stdout, C, edges) catch unreachable;
                        bw.flush() catch unreachable;
                    };
                    info_ptr.edges += 1;
                    var offset: u32 = 0;
                    var tmp_loc = C.at(q_row, q_col);
                    while (edges[tmp_loc].u) {
                        edges[tmp_loc].u = false;
                        if (offset == q_col) break;
                        offset += 1;
                        tmp_loc = C.at(q_row, q_col - offset);
                    }
                    tmp_loc = C.at(q_row, q_col);
                    offset = 0;
                    edges[tmp_loc].u = true;
                    while (edges[tmp_loc].u) {
                        edges[tmp_loc].u = false;
                        offset += 1;
                        if (offset + q_col == C.w) break;
                        tmp_loc = C.at(q_row, q_col + offset);
                    }
                }
                if (q_edges.d) {
                    info_ptr.edges += 1;
                    var offset: u32 = 0;
                    var tmp_loc = C.at(q_row, q_col);
                    while (edges[tmp_loc].d) {
                        edges[tmp_loc].d = false;
                        if (offset == q_col) break;
                        offset += 1;
                        tmp_loc = C.at(q_row, q_col - offset);
                    }
                    tmp_loc = C.at(q_row, q_col);
                    offset = 0;
                    edges[tmp_loc].d = true;
                    while (edges[tmp_loc].d) {
                        edges[tmp_loc].d = false;
                        offset += 1;
                        if (offset + q_col == C.w) break;
                        tmp_loc = C.at(q_row, q_col + offset);
                    }
                }
                if (dbg) {
                    print_edges(stdout, C, edges) catch unreachable;
                    bw.flush() catch unreachable;
                }
            }
        }
    }

    var price: usize = 0;
    var regions_iter = info_map.valueIterator();

    while (regions_iter.next()) |region| {
        // std.debug.print("[{c}] e={} a={}\n", .{ region.plant, region.edges, region.area });
        price += @intCast(region.area * region.edges);
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

fn print_edges(writer: anytype, C: Cursor, edges: []const Edges) !void {
    const lu = "┌";
    const ru = "┐";
    const lr = "│";
    const ud = "─";
    const rd = "┘";
    const ld = "└";

    try writer.writeByteNTimes('=', C.w * 3);
    try writer.writeByte('\n');
    for (0..C.h) |row| {
        for (0..C.w) |col| {
            const loc = C.at(@intCast(row), @intCast(col));
            const e = edges[loc];
            if (!e.any() or !e.any_but(.d)) {
                try writer.writeByteNTimes(' ', 3);
                continue;
            }
            try writer.writeAll(if (e.l) if (e.u) lu else lr else if (e.u) ud else " ");
            try writer.writeAll(if (e.u) ud else " ");
            try writer.writeAll(if (e.r) if (e.u) ru else lr else if (e.u) ud else " ");
        }
        try writer.writeByte('\n');
        for (0..C.w) |col| {
            const loc = C.at(@intCast(row), @intCast(col));
            const e = edges[loc];
            if (e.l or e.r) {
                try writer.writeAll(if (e.l) lr else " ");
                try writer.writeByte(' ');
                try writer.writeAll(if (e.r) lr else " ");
            } else {
                try writer.writeByteNTimes(' ', 3);
            }
        }
        try writer.writeByte('\n');
        for (0..C.w) |col| {
            const loc = C.at(@intCast(row), @intCast(col));
            const e = edges[loc];
            if (!e.any() or !e.any_but(.u)) {
                try writer.writeByteNTimes(' ', 3);
                continue;
            }
            try writer.writeAll(if (e.l) if (e.d) ld else lr else if (e.d) ud else " ");
            try writer.writeAll(if (e.d) ud else " ");
            try writer.writeAll(if (e.r) if (e.d) rd else lr else if (e.d) ud else " ");
        }
        try writer.writeByte('\n');
    }
}

fn is_one_of(comptime T: type, needle: T, comptime haystack: anytype) bool {
    const LEN = comptime haystack.len;
    const is_enum = comptime @typeInfo(T) == .Enum;
    const ElemT = if (is_enum) @typeInfo(T).Enum.tag_type else T;
    const hs: @Vector(LEN, ElemT) = comptime if (!is_enum) haystack else blk: {
        var arr: @Vector(LEN, ElemT) = undefined;
        for (haystack, 0..) |h, i| {
            arr[i] = @intFromEnum(@as(T, h));
        }
        break :blk arr;
    };
    const nd: @Vector(LEN, ElemT) = @splat(comptime if (is_enum) @intFromEnum(needle) else needle);

    return @reduce(.Or, hs == nd);
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
