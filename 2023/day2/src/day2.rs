use anyhow::{anyhow, Result};

#[derive(Debug, Clone)]
enum Color {
    Red(u32),
    Green(u32),
    Blue(u32),
}

impl std::str::FromStr for Color {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (count, color) = s
            .split_once(" ")
            .ok_or_else(|| anyhow!("in `count color` format"))?;
        let count = count
            .parse::<u32>()
            .map_err(|_| anyhow!("count is not u32"))?;
        let color = match color.trim() {
            "red" => Color::Red(count),
            "green" => Color::Green(count),
            "blue" => Color::Blue(count),
            _ => return Err(anyhow!("unknown color: {}", color)),
        };
        Ok(color)
    }
}

type Round = Vec<Color>;

#[derive(Debug, Clone)]
struct Game {
    id: u32,
    rounds: Vec<Round>,
}

impl Game {
    fn power(&self) -> u32 {
        let mut red = 1;
        let mut green = 1;
        let mut blue = 1;
        for round in &self.rounds {
            let mut r = 0;
            let mut g = 0;
            let mut b = 0;
            for color in round {
                match color {
                    Color::Red(n) => r += n,
                    Color::Green(n) => g += n,
                    Color::Blue(n) => b += n,
                }
            }
            if r > red {
                red = r;
            }
            if g > green {
                green = g;
            }
            if b > blue {
                blue = b;
            }
        }
        return red * green * blue;
    }
}

impl std::str::FromStr for Game {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (id, rounds) = s
            .split_once(": ")
            .ok_or_else(|| anyhow!("in `Game id: colors` format"))?;
        let id = id
            .strip_prefix("Game ")
            .ok_or_else(|| anyhow!("in `Game id: colors` format"))?
            .parse::<u32>()
            .map_err(|_| anyhow!("id is not u32"))?;

        let rounds = rounds
            .split("; ")
            .map(|s| s.split(", ").map(|s| s.parse::<Color>()).collect::<Result<_, _>>())
            .collect::<Result<Vec<_>, _>>()?;
        Ok(Game { id, rounds })
    }
}

fn main() -> Result<()> {
    let mut line = String::new();

    let mut sum = 0;

    while let Ok(n) = std::io::stdin().read_line(&mut line) {
        if n == 0 {
            break;
        }
        let game: Game = line.parse()?;

        sum += game.power();

        line.clear();
    }
    println!("{}", sum);
    Ok(())
}
