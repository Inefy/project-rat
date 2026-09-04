# Project R.A.T.

[![Test and deploy web game](https://github.com/Inefy/project-rat/actions/workflows/pages.yml/badge.svg)](https://github.com/Inefy/project-rat/actions/workflows/pages.yml)

**Run. Aim. Snack.** Project R.A.T. is an open-source, endless cartoon survival shooter inspired by the escalating runs of *Vampire Survivors* and the reactive arena combat of *Geometry Wars*. You are a very determined rat defending a backyard picnic from an increasingly ridiculous animal raid.

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
| Dash | `Shift` | Right shoulder |
| Toggle auto-fire | `F` | Right stick click |
| Choose mutation | `1`, `2`, or `3` | Click / tap a card |
| Pause | `P` or `Esc` | Start |

## What's in the game

- Endless wave progression with accelerating enemy health and damage, larger crowds, faster deployments, and late-run elite pressure.
- **Birds** weave through the arena at high speed.
- **Cats** stalk, telegraph, pounce, and ricochet off the arena walls.
- **Owls** maintain distance and launch three-feather volleys.
- **Snakes** slither unpredictably, kite the rat, and spit venom.
- Armoured **Raccoons** join at wave 6, brace behind trash-can lids, and charge the player.
- **Foxes** arrive at wave 10, circle the player, then telegraph a very fast ambush dash.
- Boss waves rotate between the pouncing **Alpha Cat**, armoured **Junkyard Dog**, and ranged **Barn Owl**.
- Breakable armour absorbs damage before health, is visible on the character and HUD bars, and also appears on late-run elites.
- Rare **elite raiders** have boosted stats, armour, golden badges, and a guaranteed power-up drop.
- Seven enemy drops: healing Cheese, Rapid Claws, Triple Seed, Power Nibble, Sugar Rush, Tin-lid Shield, and Needle Teeth.
- A three-card perk draft after every wave shapes the run with capped multishot, piercing, speed, health, luck, magnetism, and damage upgrades.
- An invulnerable combat dash with dedicated recharge feedback.
- Chain multipliers, wave-clear bonuses, saved high scores, controller support, hit feedback, and a complete title/pause/game-over flow.
- Pooled CC0 sound effects, varied pitch, camera shake, and stronger combat feedback.
- A 2400×1400 camera-tracked storybook backyard with a picnic blanket, flowers, stepping stones, animated ink-outlined characters, comic impact effects, and a custom reticle.

## Difficulty progression

| Wave | New pressure |
| --- | --- |
| 3 | Ranged owls and armoured elite variants begin appearing. |
| 4 | Venom-spitting snakes join the mix. |
| 5 | Alpha Cat boss. |
| 6 | Armoured raccoons join regular waves. |
| 10 | Fox ambushers and the armoured Junkyard Dog boss arrive. |
| 15 | The Barn Owl boss introduces a seven-feather ranged fan. |
| 20+ | Faster spawn pacing, denser waves, accelerating stats, and a high late-run armour share. |

## Project layout

```text
scenes/main.tscn        Entry scene
scripts/main.gd         Run, wave, spawning, score, and persistence systems
scripts/player.gd       Rat movement, aiming, weapon, health, and mutations
scripts/enemy.gd        Bird, cat, owl, snake, elite, and Alpha Cat behavior
scripts/hud.gd          Title screen, HUD, pause, and game-over UI
scripts/audio_manager.gd Pooled web-safe sound playback
scripts/power_up.gd     Drop behavior and visual language
assets/audio/           Curated CC0 sound effects
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

Third-party audio is CC0 and documented in [ASSETS.md](ASSETS.md).
