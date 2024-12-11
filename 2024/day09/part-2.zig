const std = @import("std");

const input = @embedFile("./input.txt");

const File = struct {
    blocks: u8,
    empty: bool,
    id: u32,
};

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;

    var fs = std.MultiArrayList(File){};

    {
        var is_empty = false;
        var cur_id: u32 = 0;
        for (input) |ch| {
            defer {
                is_empty = !is_empty;
                if (is_empty) {
                    cur_id += 1;
                }
            }
            const blocks = std.fmt.parseUnsigned(u8, &.{ch}, 10) catch break;
            // try fs.ensureUnusedCapacity(alloc, blocks);
            try fs.append(alloc, .{
                .blocks = blocks,
                .empty = is_empty,
                .id = cur_id,
            });
        }
    }

    try stdout.print("fs len: {d}\n", .{fs.len});

    // try print_fs(stdout, fs);

    var slice = fs.slice();

    var idx = std.mem.lastIndexOfScalar(bool, slice.items(.empty), false).?;

    outer: while (idx > 0) : (idx = std.mem.lastIndexOfScalar(bool, slice.items(.empty)[0..idx], false) orelse 0) {
        const blocks = slice.items(.blocks);
        var front = std.mem.indexOfScalar(bool, slice.items(.empty)[0..idx], true) orelse continue;
        while (blocks[front] < blocks[idx]) {
            front = std.mem.indexOfScalarPos(bool, slice.items(.empty)[0..idx], front + 1, true) orelse continue :outer;
        }

        const empty_blocks = blocks[front];
        const full_blocks = blocks[idx];

        var tmp = slice.get(front);
        slice.set(front, slice.get(idx));
        tmp.blocks = full_blocks;
        slice.set(idx, tmp);

        if (empty_blocks > full_blocks) {
            try fs.insert(alloc, front + 1, .{
                .blocks = empty_blocks - full_blocks,
                .empty = true,
                .id = 0,
            });
            slice = fs.slice();
            idx += 1;
        }

        // try print_fs(stdout, fs);
    }

    // try print_fs(stdout, fs);

    var checksum: usize = 0;

    var total_blocks: usize = 0;

    for (fs.items(.id), fs.items(.empty), fs.items(.blocks)) |id, empty, blocks| {
        if (!empty) {
            for (0..blocks) |blks| {
                checksum += (blks + total_blocks) * id;
            }
        }
        total_blocks += blocks;
    }

    try stdout.print("checksum: {}\n", .{checksum});

    try bw.flush();
}

fn print_fs(writer: anytype, fs: std.MultiArrayList(File)) !void {
    var slice = fs.slice();
    const blockss = slice.items(.blocks);
    const emptys = slice.items(.empty);
    const ids = slice.items(.id);
    for (blockss, emptys, ids) |blocks, empty, id| {
        if (empty) {
            try writer.writeByteNTimes('.', blocks);
        } else {
            for (0..blocks) |_| {
                try writer.print(" {} ", .{id});
            }
        }
    }
    try writer.writeAll("\n");
}
