const argv = process.argv.slice(2);

const a = Number.parseInt(argv[0]);
const b = Number.parseInt(argv[1]);
const dest = Number.parseInt(argv[2]);

let dp = new Array(dest).fill(false);
dp[0] = true;

for (let i = 1; i <= dest + 1; i++) {
  if (i >= a) dp[i] = dp[i] || dp[i - a];

  if (i >= b) dp[i] = dp[i] || dp[i - b];
}
console.log(dp[dest]);
