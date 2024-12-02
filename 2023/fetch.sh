#!/usr/bin/bash

DAY=$1

SESSION=53616c7465645f5ffa22806604cdc9e1f56f685404874df74743484695dc8c9383da72da735a9703f90a1e96698122ae6f1065e1d3b854a4b47b1f0b15d688aa

curl -o ./day${DAY}/input.txt "https://adventofcode.com/2020/day/$DAY/input" -H "cookie: session=${SESSION}"
