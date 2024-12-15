def coin_change(coins, amount):
    n = len(coins)
    dp = [[0] * (amount + 1) for _ in range(n + 1)]
    combinations = [[[] for _ in range(amount + 1)] for _ in range(n + 1)]

    for i in range(n + 1):
        dp[i][0] = 1
        combinations[i][0] = [[]]

    for i in range(1, n + 1):
        for row in dp:
            print(row)
        print("=" * amount * 2);
        for j in range(1, amount + 1):
            dp[i][j] = dp[i-1][j]
            combinations[i][j] = combinations[i-1][j][:]

            if j >= coins[i-1]:
                dp[i][j] += dp[i][j-coins[i-1]]
                for comb in combinations[i][j-coins[i-1]]:
                    new_comb = comb + [coins[i-1]]
                    combinations[i][j].append(new_comb)

            for row in dp:
                print(row)
            print("=" * amount * 2);
        print("=" * amount * 2);
        print("=" * amount * 2);

    return dp[n][amount], combinations[n][amount]

# Example usage
coins = [1, 2]
amount = 5
count, combs = coin_change(coins, amount)
print(f"Number of combinations: {count}")
print(f"Possible combinations: {combs}")