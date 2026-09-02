# Project R.A.T.

[![Test and deploy web game](https://github.com/Inefy/project-rat/actions/workflows/pages.yml/badge.svg)](https://github.com/Inefy/project-rat/actions/workflows/pages.yml)

**Run. Aim. Thrive.** Project R.A.T. is an open-source, endless neon survival shooter inspired by the escalating runs of *Vampire Survivors* and the reactive arena combat of *Geometry Wars*. You are a very determined rat trapped in a predator-infested sewer grid.

Built with Godot 4.7.2 and designed to run natively in modern desktop browsers.

## Play

**[Play Project R.A.T. in your browser](https://zacbatten.me/project-rat/)**

The latest `main` branch is automatically tested, exported, and deployed to GitHub Pages after every push.

To play locally:

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import `project.godot` in the Project Manager.
3. Press **F6** or **F5**.

No third-party art, fonts, plug-ins, or asset packs are required. Every character and effect is drawn procedurally in GDScript.

## Controls

| Action | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | `WASD` or arrow keys | Left stick |
| Aim | Mouse | Right stick |
| Fire | Automatic by default; left click or `Space` when disabled | Right stick |
| Toggle auto-fire | `F` | Right stick click |
| Pause | `P` or `Esc` | Back / Select |

## What's in the game

- Endless wave progression with enemy health, damage, count, and spawn-rate scaling.
- **Birds** weave through the arena at high speed.
- **Cats** stalk, telegraph, pounce, and ricochet off the arena walls.
- **Owls** maintain distance and launch three-feather volleys.
- An **Alpha Cat** arrives every fifth wave with a high-speed pounce and radial sonic attack.
- Seven enemy drops: healing Cheese, Rapid Claws, Triple Seed, Power Nibble, Sugar Rush, Tin-can Shield, and Needle Teeth.
- Chain multipliers, wave-clear bonuses, saved high scores, controller support, hit feedback, and a complete title/pause/game-over flow.
- A 2400×1400 camera-tracked neon arena with landmarks, animated procedural characters, glow effects, and a custom reticle.

## Project layout

```text
scenes/main.tscn        Entry scene
scripts/main.gd         Run, wave, spawning, score, and persistence systems
scripts/player.gd       Rat movement, aiming, weapon, health, and mutations
scripts/enemy.gd        Bird, cat, owl, and Alpha Cat behavior and art
scripts/hud.gd          Title screen, HUD, pause, and game-over UI
scripts/power_up.gd     Drop behavior and visual language
tests/smoke_test.gd     Headless gameplay smoke test
export_presets.cfg      Web export configuration
```

## Test and export

Run the smoke test:

```bash
godot --headless --path . --script tests/smoke_test.gd
```

Create the browser build after installing Godot's export templates:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

The GitHub Actions workflow runs both commands and deploys a Pages artifact automatically.

## Contributing

Enemy archetypes, power-ups, juice, accessibility options, audio, and balance passes are all welcome. Keep new runtime dependencies web-compatible and add a focused smoke check when introducing a new system.

## License

[MIT](LICENSE)
