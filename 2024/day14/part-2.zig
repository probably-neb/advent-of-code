const std = @import("std");

const input_file = "./input.txt";
const input = @embedFile(input_file);
const is_smol = std.mem.indexOfPos(u8, input_file, "./input".len, "smol") != null;
const GRID_W = if (is_smol) 11 else 101;
const GRID_H = if (is_smol) 7 else 103;
const ROBOT_COUNT = if (is_smol) if (std.mem.indexOf(u8, input_file, "smoller") != null) 1 else 12 else 500;

const COST_A = 3;
const COST_B = 1;

const Robot = struct {
    pos: Vec2,
    velocity: IVec2,

    const Vec2 = struct {
        x: u32,
        y: u32,
    };

    const IVec2 = struct {
        x: i32,
        y: i32,
    };
};

pub fn main() !void {
    std.debug.print("GRID_H={} GRID_W={}\n", .{ GRID_H, GRID_W });
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var line_idx: u32 = 0;

    var robots: [ROBOT_COUNT]Robot = undefined;

    while (line_iter.next()) |line| : (line_idx += 1) {
        const pos_vel = split_N_times(u8, line, ' ', 2);
        const pos_x_y = split_N_times(u8, strip_prefix_exact(u8, pos_vel[0], "p="), ',', 2);
        const vel_x_y = split_N_times(u8, strip_prefix_exact(u8, pos_vel[1], "v="), ',', 2);

        const pos_x = try std.fmt.parseUnsigned(u32, pos_x_y[0], 10);
        const pos_y = try std.fmt.parseUnsigned(u32, pos_x_y[1], 10);

        const vel_x = try std.fmt.parseInt(i32, vel_x_y[0], 10);
        const vel_y = try std.fmt.parseInt(i32, vel_x_y[1], 10);

        robots[line_idx] = .{
            .pos = .{
                .x = pos_x,
                .y = pos_y,
            },
            .velocity = .{
                .x = vel_x,
                .y = vel_y,
            },
        };
    }
    std.debug.assert(line_idx == ROBOT_COUNT);

    var i: u32 = 0;
    var grid: [GRID_H][GRID_W]u8 = undefined;

    while (true) : (i += 1) {
        {
            for (0..GRID_H) |r| {
                @memset(&grid[r], 0);
            }

            for (robots) |robot| {
                grid[robot.pos.y][robot.pos.x] += 1;
            }
            var total_adj: u32 = 0;
            for (robots) |robot| {
                const x = robot.pos.x;
                const y = robot.pos.y;

                if (y > 0) {
                    total_adj += grid[y - 1][x];
                }
                if (y > 0 and x > 0) {
                    total_adj += grid[y - 1][x - 1];
                }
                if (y > 0 and x < GRID_W - 1) {
                    total_adj += grid[y - 1][x + 1];
                }
                if (y < GRID_H - 1) {
                    total_adj += grid[y + 1][x];
                }
                if (y < GRID_H - 1 and x > 0) {
                    total_adj += grid[y + 1][x - 1];
                }
                if (y < GRID_H - 1 and x < GRID_W - 1) {
                    total_adj += grid[y + 1][x + 1];
                }
                if (x > 0) {
                    total_adj += grid[y][x - 1];
                }
                if (x < GRID_W - 1) {
                    total_adj += grid[y][x + 1];
                }
            }
            const avg_adj = total_adj / ROBOT_COUNT;
            if (avg_adj > 0) {
                print_robots(&robots, false);
                std.debug.print("I = {} AVG ADJ = {}\n", .{ i, avg_adj });
                std.time.sleep(std.time.ns_per_s);
            }
        }
        for (&robots) |*robot| {
            if (robot.velocity.x < 0) {
                if (robot.pos.x < @abs(robot.velocity.x)) {
                    robot.pos.x = GRID_W + robot.pos.x - @abs(robot.velocity.x);
                } else {
                    robot.pos.x -= @abs(robot.velocity.x);
                }
            } else {
                robot.pos.x += @intCast(robot.velocity.x);
                if (robot.pos.x >= GRID_W) {
                    robot.pos.x -= GRID_W;
                }
            }
            if (robot.velocity.y < 0) {
                if (robot.pos.y < @abs(robot.velocity.y)) {
                    robot.pos.y = GRID_H + robot.pos.y - @abs(robot.velocity.y);
                } else {
                    robot.pos.y -= @abs(robot.velocity.y);
                }
            } else {
                robot.pos.y += @intCast(robot.velocity.y);
                if (robot.pos.y >= GRID_H) {
                    robot.pos.y -= GRID_H;
                }
            }
        }
        // std.time.sleep(std.time.ns_per_s);
    }
}

fn print_robots(robots: *const [ROBOT_COUNT]Robot, hide_mid: bool) void {
    const mid_x = (GRID_W - 1) / 2;
    const mid_y = (GRID_H - 1) / 2;

    var grid: [GRID_H][GRID_W]u8 = undefined;
    for (0..GRID_H) |r| {
        @memset(&grid[r], '.');
    }

    for (robots) |robot| {
        if (grid[robot.pos.y][robot.pos.x] == '.') {
            grid[robot.pos.y][robot.pos.x] = '0';
        }
        grid[robot.pos.y][robot.pos.x] += 1;
    }

    if (hide_mid) {
        @memset(&grid[mid_y], ' ');
        for (0..GRID_H) |row| {
            grid[row][mid_x] = ' ';
        }
    }

    std.debug.print("{s}\n", .{"=" ** GRID_W});
    for (0..GRID_H) |row| {
        std.debug.print("{s}\n", .{grid[row]});
    }
    std.debug.print("{s}\n", .{"=" ** GRID_W});
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
