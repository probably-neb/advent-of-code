const std = @import("std");

const input = @embedFile("./input.txt");

const COST_A = 3;
const COST_B = 1;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const alloc = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(alloc);
    const arena_alloc = arena.allocator();

    var machine_iter = std.mem.tokenizeSequence(u8, input, "\n\n");

    var tokens: usize = 0;

    while (machine_iter.next()) |machine_str| {
        defer _ = arena.reset(.retain_capacity);
        const lines = split_N_times(u8, machine_str, '\n', 3);
        const a = lines[0];
        const a_offset_str = strip_prefix_exact(u8, a, "Button A: ");
        const a_offset = try parse_offset(a_offset_str);

        const b = lines[1];
        const b_offset_str = strip_prefix_exact(u8, b, "Button B: ");
        const b_offset = try parse_offset(b_offset_str);

        const prize = lines[2];
        const prize_offset_str = strip_prefix_exact(u8, prize, "Prize: ");
        const prize_offset = try parse_offset(prize_offset_str);

        const is_possible_x = try can_reach(arena_alloc, a_offset.x, b_offset.x, prize_offset.x);
        const is_possible_y = try can_reach(arena_alloc, a_offset.y, b_offset.y, prize_offset.y);

        if (!is_possible_x.possible or !is_possible_y.possible) {
            // std.debug.print("NOT POSSIBLE: \n{s}\n", .{machine_str});
            continue;
        }

        var min_cost: u32 = std.math.maxInt(u32);
        var found = false;

        for (is_possible_x.combos) |x| {
            for (is_possible_y.combos) |y| {
                if (x.A == y.A and x.B == y.B) {
                    found = true;
                    const cost = (x.A * COST_A + x.B * COST_B);
                    if (min_cost > cost) {
                        // std.debug.print("min cost = {} A={} B={}\n", .{ cost, x.A, x.B });
                        min_cost = cost;
                    }
                }
            }
        }

        if (found) {
            tokens += min_cost;
        }

        // std.debug.assert(a_offset.x * 100 >= prize_offset.x);
        // std.debug.assert(a_offset.y * 100 >= prize_offset.y);
        // std.debug.assert(b_offset.x * 100 >= prize_offset.x);
        // std.debug.assert(b_offset.y * 100 >= prize_offset.y);
    }

    try stdout.print("price: {}\n", .{tokens});

    try bw.flush();
}

const Combo = struct {
    A: u32,
    B: u32,
};

fn can_reach(alloc: std.mem.Allocator, a: u32, b: u32, target: u32) !struct { possible: bool, combos: []const Combo } {
    if (target < @min(a, b)) {
        return .{
            .possible = false,
            .combos = &.{},
        };
    }
    var bs = try std.DynamicBitSet.initEmpty(alloc, target + 1);
    defer bs.deinit();
    bs.set(0);
    for (1..target + 1) |i| {
        var is_set = bs.isSet(i);
        if (i >= a) {
            is_set = is_set or bs.isSet(i - a);
            bs.setValue(i, is_set);
        }
        if (i >= b) {
            bs.setValue(i, is_set or bs.isSet(i - b));
        }
    }
    // std.debug.print("can_reach: a={} b={} Prize={} := {}\n", .{a, b, target, bs.isSet(target)});
    const possible = bs.isSet(target);
    if (!possible) {
        return .{
            .possible = false,
            .combos = &.{},
        };
    }

    var combos = try alloc.alloc([]Combo, target + 1);
    for (combos) |*combo| {
        combo.len = 0;
    }
    var base = [1]Combo{.{
        .A = 0,
        .B = 0,
    }};
    combos[0] = &base;
    for (1..target + 1) |i| {
        if (!bs.isSet(i)) {
            continue;
        }
        const a_ok = i >= a and bs.isSet(i - a);
        const b_ok = i >= b and bs.isSet(i - b);
        if (a_ok and b_ok) {
            const a_combos = combos[i - a];
            const b_combos = combos[i - b];
            var new_combos = try std.ArrayList(Combo).initCapacity(alloc, a_combos.len + b_combos.len);
            defer new_combos.deinit();

            for (a_combos) |a_combo| {
                const is_dup = is_dup: for (b_combos) |b_combo| {
                    if (a_combo.A + 1 == b_combo.A and a_combo.B == b_combo.B + 1) {
                        break :is_dup true;
                    }
                } else false;
                if (is_dup) continue;
                const ptr = new_combos.addOneAssumeCapacity();
                ptr.* = a_combo;
                ptr.A += 1;
            }
            for (b_combos) |b_combo| {
                const ptr = new_combos.addOneAssumeCapacity();
                ptr.* = b_combo;
                ptr.B += 1;
            }

            combos[i] = try new_combos.toOwnedSlice();
        } else if (a_ok and !b_ok) {
            const new_combos = try alloc.dupe(Combo, combos[i - a]);
            for (new_combos) |*combo| {
                combo.A += 1;
            }
            combos[i] = new_combos;
        } else if (b_ok and !a_ok) {
            const new_combos = try alloc.dupe(Combo, combos[i - b]);
            for (new_combos) |*combo| {
                combo.B += 1;
            }
            combos[i] = new_combos;
        } else {
            unreachable;
        }
    }

    return .{
        .possible = true,
        .combos = combos[target],
    };
}

const Offset = struct {
    x: u32,
    y: u32,
};
fn parse_offset(str: []const u8) !Offset {
    const x_y = split_N_times_seq(u8, str, ", ", 2);
    const x = try std.fmt.parseUnsigned(u32, x_y[0][2..], 10);
    const y = try std.fmt.parseUnsigned(u32, x_y[1][2..], 10);
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
