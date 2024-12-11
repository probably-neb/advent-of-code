const std = @import("std");

const input = @embedFile("./input.txt");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var w: usize = 0;
    var h: usize = 0;

    var grid_lst = std.ArrayList([]const u8).init(alloc);

    {
        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            w = line.len;
            h += 1;

            var nums = try alloc.alloc(u8, w);
            for (line, 0..) |char, i| {
                nums[i] = char - '0';
            }
            try grid_lst.append(nums);
        }
    }

    const grid = grid_lst.items;

    var queue = std.ArrayList(struct {
        x: usize,
        y: usize,
    }).init(alloc);

    for (0..h) |row| {
        for (0..w) |col| {
            if (grid[row][col] == 0) {
                try queue.append(.{
                    .x = col,
                    .y = row,
                });
            }
        }
    }
    const grid_copy = blk: {
        var cpy = try alloc.alloc([]u8, h);
        for (0..h) |row| {
            cpy[row] = try alloc.alloc(u8, w);
            @memset(cpy[row], '.');
        }
        break :blk cpy;
    };

    var visited = blk: {
        var visited = try alloc.alloc([]bool, h);
        for (0..h) |row| {
            visited[row] = try alloc.alloc(bool, w);
            @memset(visited[row], false);
        }
        break :blk visited;
    };

    std.debug.print("queue.len = {}\n", .{queue.items.len});

    var count: usize = 0;

    while (queue.popOrNull()) |loc| {
        const val = grid[loc.y][loc.x];

        if (val == 0) {
            for (0..h) |row| {
                @memset(grid_copy[row], '.');
                @memset(visited[row], false);
            }
        }

        {
            const green = "\x1b[32m";
            const reset = "\x1b[0m";
            grid_copy[loc.y][loc.x] = val + '0';
            try stdout.print("count: {}\n", .{count});
            try stdout.writeByteNTimes('=', w);
            try stdout.writeByte('\n');
            for (0..h) |row| {
                if (row == loc.y) {
                    try stdout.writeAll(grid_copy[row][0..loc.x]);
                    try stdout.writeAll(green);
                    try stdout.writeByte(val + '0');
                    try stdout.writeAll(reset);
                    try stdout.writeAll(grid_copy[row][loc.x + 1 ..]);
                } else {
                    try stdout.writeAll(grid_copy[row]);
                }
                try stdout.writeByte('\n');
            }
            try stdout.writeByteNTimes('=', w);
            try stdout.writeByte('\n');
            try bw.flush();
        }

        if (val == 9) {
            if (!visited[loc.y][loc.x]) {
                visited[loc.y][loc.x] = true;
                count += 1;
            }
            continue;
        }

        // left
        if (loc.x > 0 and grid[loc.y][loc.x - 1] == val + 1) {
            try queue.append(.{
                .x = loc.x - 1,
                .y = loc.y,
            });
        }
        // right
        if (loc.x < w - 1 and grid[loc.y][loc.x + 1] == val + 1) {
            try queue.append(.{
                .x = loc.x + 1,
                .y = loc.y,
            });
        }
        // up
        if (loc.y > 0 and grid[loc.y - 1][loc.x] == val + 1) {
            try queue.append(.{
                .x = loc.x,
                .y = loc.y - 1,
            });
        }
        // down
        if (loc.y < h - 1 and grid[loc.y + 1][loc.x] == val + 1) {
            try queue.append(.{
                .x = loc.x,
                .y = loc.y + 1,
            });
        }
    }

    try stdout.print("count: {}\n", .{count});

    try bw.flush();
}
