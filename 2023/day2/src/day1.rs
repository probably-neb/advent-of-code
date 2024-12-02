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

#[derive(Debug, Clone)]
struct Config {
    red: u32,
    green: u32,
    blue: u32,
}

impl Config {
    fn verify(&self, g: &Game) -> Result<()> {
        for (i, round) in g.rounds.iter().enumerate() {
            let mut red = 0;
            let mut green = 0;
            let mut blue = 0;
            for color in round {
                match color {
                    Color::Red(n) => red += n,
                    Color::Green(n) => green += n,
                    Color::Blue(n) => blue += n,
                }
            }
            match (red, green, blue) {
                (red,_,_) if red > self.red => return Err(anyhow!("too many red in round {:?}", i)),
                (_,green,_) if green > self.green => return Err(anyhow!("too many green in round {:?}", i)),
                (_,_,blue) if blue > self.blue => return Err(anyhow!("too many blue in round {:?}", i)),
                _ => (),
            }
        }
        Ok(())
    }
}

fn main() -> Result<()> {
    let mut line = String::new();
    let config = Config {red: 12, green: 13, blue: 14};

    let mut sum = 0;

    while let Ok(n) = std::io::stdin().read_line(&mut line) {
        if n == 0 {
            break;
        }
        let game = line.parse::<Game>()?;

        match config.verify(&game) {
            Ok(()) => sum += game.id,
            Err(msg) => eprintln!("{} of game {}", msg, game.id),
        }

        line.clear();
    }
    println!("{}", sum);
    Ok(())
}
