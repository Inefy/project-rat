# Project R.A.T.

[![Test and deploy web game](https://github.com/Inefy/project-rat/actions/workflows/pages.yml/badge.svg)](https://github.com/Inefy/project-rat/actions/workflows/pages.yml)

**Run. Aim. Snack.** Project R.A.T. is an open-source cartoon survival shooter inspired by the escalating runs of *Vampire Survivors* and the reactive arena combat of *Geometry Wars*. You are a very determined rat defending a backyard picnic from an increasingly ridiculous animal raid. Save the picnic across 15 waves, then choose whether to keep going in endless overtime.

Built with Godot 4.7.2 and designed to run natively in modern desktop browsers.

## Play

**[Play Project R.A.T. in your browser](https://zacbatten.me/project-rat/)**

The latest `main` branch is automatically tested, exported, and deployed to GitHub Pages after every push.

To play locally:

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import `project.godot` in the Project Manager.
3. Press **F6** or **F5**.


Gameplay characters, pickups, projectiles, and explosive props use 94 transparent sprites rendered from 24 original Blender models. Characters have eight facings with runtime bounce and squash. Editable models, GLB exports, and the concept sheet are in `art/`; the production guide is `art/README.md`. Combat effects remain procedural. Bundled CC0 Kenney art decorates the backyard; credits are in `ASSETS.md`. No external plug-ins are required to play.

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

Open **Comfort & Controls** from the title or pause menu for saved keyboard remapping, volume, shake intensity, larger text, gentle aim assist, Cozy difficulty, and optional gameplay hints. Controller users can navigate menus and mutation cards with the directional controls and confirm with the standard accept button. Releasing the aiming stick preserves its direction.

## Build your rat

The first wave-clear draft offers three ways to play:

- **Pinball Rat:** seeds rebound off the fence; Split Decision adds a secondary seed on the rebound.
- **Scurry Menace:** every dash leaves an explosive crumb; Crumb Back refunds 0.4 seconds of recharge when the blast hits.
- **Snack Wizard:** collected treats charge three orbiting seeds; Full Plate raises the orbit to five. Pickup-range upgrades help keep it active.

Later drafts mix stat upgrades with eligible build synergies. Cards show upgrade levels and stat changes; pause to inspect the complete build. Bosses guarantee banked Power and Shield treats plus a bonus mutation draft at wave clear. Leftover treats are banked until the next wave. Full health/shield pickups convert into temporary power, and Triple Seed adds two seeds even to an upgraded weapon.

Encounter recipes alternate bird swarms, cat pincers, ranged sieges, and elite hunts, with short recovery gaps and crowd limits. Yellow attack lines indicate a wind-up; red lines indicate a committed direction. Offscreen threats and final stragglers get edge markers. Shoot the marked fizzy cans to knock nearby enemies away.

Pausing and drafting freeze gameplay and its timers. When all mutations are exhausted, subsequent wave clears award health and score without blocking the run.

## What's in the game

- A 15-wave picnic defense followed by optional endless overtime, with growing crowds, faster deployments, and late-run elite pressure.
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
godot --headless --path . --script tests/fun_systems_test.gd
```

Create the browser build after installing Godot's export templates:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

The GitHub Actions workflow runs both test suites, exports the game, and deploys a Pages artifact automatically. `tests/capture_fun_preview.gd` can also be run with the graphical engine to capture title, settings, draft, gameplay, pause, victory, and game-over screenshots in `build/`.

The implementation and regression tests support a first human playtest; they do not establish that a balance choice is more fun. See [FUN_AUDIT.md](FUN_AUDIT.md) for the playtest plan and later experiments such as unlockable kits and shared seeded challenges.

## Contributing

Enemy archetypes, power-ups, juice, accessibility options, audio, and balance passes are all welcome. Keep new runtime dependencies web-compatible and add a focused smoke check when introducing a new system.

## License

[MIT](LICENSE)

Third-party audio is CC0 and documented in [ASSETS.md](ASSETS.md).
