const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;

pub fn coinChange(allocator: std.mem.Allocator, amount: u32, coins: []const u32) !void {
    // Create a DP table to store minimum coins needed
    var dp = try allocator.alloc(u32, @as(usize, amount) + 1);
    defer allocator.free(dp);
    @memset(dp, std.math.maxInt(u32));
    dp[0] = 0;

    // Create a table to track coin combinations
    var combinations = try allocator.alloc(ArrayList([]const u32), @as(usize, amount) + 1);
    defer {
        for (combinations) |list| {
            list.deinit();
        }
        allocator.free(combinations);
    }

    // Initialize combinations array
    for (0..combinations.len) |i| {
        combinations[i] = ArrayList([]const u32).init(allocator);
    }

    // Empty combination for amount 0
    try combinations[0].append(&[_]u32{});

    // Iterate through all amounts from 1 to target
    for (1..dp.len) |current_amount| {
        for (coins) |coin| {
            if (coin <= current_amount) {
                const prev_amount = current_amount - coin;

                // Check if we can improve the number of coins
                const potential_coins = dp[prev_amount] + 1;

                if (potential_coins < dp[current_amount]) {
                    // Reset combinations if we find a better solution
                    combinations[current_amount].clearAndFree();
                    dp[current_amount] = potential_coins;
                }

                // If we find an equally good solution
                if (potential_coins == dp[current_amount]) {
                    // For each previous combination, create a new one by adding the current coin
                    for (combinations[prev_amount].items) |prev_combination| {
                        var new_combination = try ArrayList(u32).initCapacity(allocator, prev_combination.len + 1);
                        defer new_combination.deinit();

                        new_combination.appendSlice(prev_combination) catch unreachable;
                        new_combination.append(coin) catch unreachable;

                        try combinations[current_amount].append(new_combination.items);
                    }
                }
            }
        }
    }

    // Print results
    print("Amount: {}\n", .{amount});
    print("Minimum number of coins: {}\n", .{dp[amount]});

    print("Possible coin combinations:\n", .{});
    for (combinations[amount].items) |combination| {
        print("  ", .{});
        for (combination) |coin| {
            print("{} ", .{coin});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Example with two coin denominations
    const coins = [_]u32{ 1, 5 };
    const target_amount: u32 = 11;

    try coinChange(allocator, target_amount, &coins);
}
