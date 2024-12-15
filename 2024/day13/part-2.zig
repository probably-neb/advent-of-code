const std = @import("std");

const input = @embedFile("./input.txt");

const COST_A = 3;
const COST_B = 1;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var tokens: u128 = 0;

    var machine_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    while (machine_iter.next()) |machine_str| {
        // defer _ = arena.reset(.retain_capacity);
        const lines = split_N_times(u8, machine_str, '\n', 3);
        const a = lines[0];
        const a_offset_str = strip_prefix_exact(u8, a, "Button A: ");
        const A = try parse_offset(a_offset_str);

        const b = lines[1];
        const b_offset_str = strip_prefix_exact(u8, b, "Button B: ");
        const B = try parse_offset(b_offset_str);

        const prize = lines[2];
        const prize_offset_str = strip_prefix_exact(u8, prize, "Prize: ");
        var P = try parse_offset(prize_offset_str);
        P.x += 10_000_000_000_000;
        P.y += 10_000_000_000_000;
        P.x += 0;
        P.y += 0;

        // x * A.x + y * B.x = P.x
        // x * A.y + y * B.y = P.y

        const x_float = (P.y - (P.x * B.y) / B.x) / (A.y - (A.x * B.y) / B.x);
        const y_float = (P.x - (x_float * A.x)) / B.x;

        const x = whole_number(x_float) orelse continue;
        const y = whole_number(y_float) orelse continue;

        tokens += x * COST_A + y * COST_B;
    }

    try stdout.print("price: {}\n", .{tokens});

    try bw.flush();
}

fn whole_number(f: f64) ?u128 {
    if (f < 0) {
        return null;
    }
    const i: u128 = @intFromFloat(@round(f));
    const i_f: f64 = @floatFromInt(i);
    if (!std.math.approxEqAbs(f64, i_f, f, 0.001)) {
        // std.debug.print("diff: {}\n", .{@abs(i_f - f)});
        return null;
    }
    return i;
}

const Vec2 = struct {
    x: f64,
    y: f64,
};

fn solve(A: Vec2, B: Vec2, P: Vec2) ?Vec2 {
    const det = A.x * B.y - A.y * B.x;
    if (std.math.approxEqAbs(f32, det, 0, 1e-6)) {
        return null;
    }
    const x = (P.x * B.y - P.y * B.x) / det;
    const y = (A.x * P.y - A.y * P.y) / det;

    return Vec2{ .x = x, .y = y };
}

const Offset = struct {
    x: usize,
    y: usize,
};

fn parse_offset(str: []const u8) !Vec2 {
    const x_y = split_N_times_seq(u8, str, ", ", 2);
    const x = try std.fmt.parseFloat(f64, x_y[0][2..]);
    const y = try std.fmt.parseFloat(f64, x_y[1][2..]);
    return .{
        .x = x,
        .y = y,
    };
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
