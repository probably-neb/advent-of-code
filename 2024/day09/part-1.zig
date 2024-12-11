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
            try fs.ensureUnusedCapacity(alloc, blocks);
            for (0..blocks) |_| {
                fs.appendAssumeCapacity(.{
                    .blocks = blocks,
                    .empty = is_empty,
                    .id = cur_id,
                });
            }
        }
    }

    try stdout.print("fs len: {d}\n", .{fs.len});

    // try print_fs(stdout, fs);

    var last_non_empty_index = std.mem.lastIndexOfScalar(bool, fs.items(.empty), false);
    var first_empty_index = std.mem.indexOfScalar(bool, fs.items(.empty), true);
    while (first_empty_index != null and last_non_empty_index.? > first_empty_index.?) : ({
        last_non_empty_index = std.mem.lastIndexOfScalar(bool, fs.items(.empty), false);
        first_empty_index = std.mem.indexOfScalar(bool, fs.items(.empty), true);
    }) {
        fs.swapRemove(first_empty_index.?);
        // try print_fs(stdout, fs);
    }

    // try print_fs(stdout, fs);

    var checksum: usize = 0;

    for (fs.items(.id), fs.items(.empty), 0..) |id, empty, pos| {
        if (!empty) {
            checksum += pos * id;
        }
    }

    try stdout.print("checksum: {}\n", .{checksum});

    try bw.flush();
}

fn print_fs(writer: anytype, fs: std.MultiArrayList(File)) !void {
    var slice = fs.slice();
    const emptys = slice.items(.empty);
    const ids = slice.items(.id);
    for (emptys, ids) |empty, id| {
        if (empty) {
            try writer.writeByte('.');
        } else {
            try writer.print(" {} ", .{id});
        }
    }
    try writer.writeAll("\n");
}
