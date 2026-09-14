# Project R.A.T.

[![Test and deploy web game](https://github.com/Inefy/project-rat/actions/workflows/pages.yml/badge.svg)](https://github.com/Inefy/project-rat/actions/workflows/pages.yml)

**Top-down browser game.** Aim around the rat in the nightmare garden, with independent movement and an overhead view of incoming attacks.

**Run. Aim. Snack.** Project R.A.T. is an open-source cartoon survival shooter inspired by the escalating runs of *Vampire Survivors* and the reactive arena combat of *Geometry Wars*. You are a very determined rat defending a backyard picnic from an increasingly ridiculous animal raid. Save the picnic across 15 waves, then choose whether to keep going in endless overtime.

Built with Godot 4.7.2 and designed to run natively in modern desktop browsers.

## Play

**[Play Project R.A.T. in your browser](https://zacbatten.me/project-rat/)**

The latest `main` branch is automatically tested, exported, and deployed to GitHub Pages after every push.

To play locally:

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import `project.godot` in the Project Manager.
3. Press **F6** or **F5**.


Enemies, pickups, projectiles, and props use lightweight sprites rendered from the original Blender models. Movement, collisions, waves, and upgrades run in 2D. Editable models, GLB exports, and the concept sheet are in `art/`; the production guide is `art/README.md`. Combat effects remain procedural. Bundled CC0 Kenney art decorates the backyard; credits are in `ASSETS.md`. No external plug-ins are required to play.

The regular cat uses the reference-based black creature with green ring eyes, human-like hands, bloodied fangs, and a curved blade tail. Its eight 192px directional sprites total 221 KiB. The editable Blender source is `art/cat/reference-cat.blend`; the 407 KiB GLB is retained for editing and reuse and excluded from the top-down browser download.

The fox uses the supplied orange creature with human ears, sleepy eyes, white muzzle and chest markings, a pink tongue, and a curled white-tipped tail. Its eight Blender-rendered 192px directions total 176 KiB. The editable source is `art/fox/reference-fox.blend`; the 518 KiB GLB is retained for reuse. The replacement keeps the fox's wave-ten arrival, warning, ambush dash, and recovery window. Preview and in-game captures are in `art/fox/`.

## Controls

| Action | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | `WASD`, in screen directions | Left stick |
| Aim | Mouse or arrow keys | Right stick |
| Fire | Automatic by default; hold arrow keys, left click or `Space` when disabled | Right stick |
| Dash | `Shift` | Right shoulder |
| Toggle auto-fire | `F` | Right stick click |
| Choose mutation | `1`, `2`, or `3` | Click / tap a card |
| Pause | `P` or `Esc` | Start |

Move with **WASD** and aim at the **mouse cursor**. For keyboard-only play, the **arrow keys** aim in eight directions; holding them also fires. Releasing aim input preserves your direction. **Esc** pauses, showing the menu cursor. Resume restores the aiming reticle. Offscreen indicators reveal incoming attack wind-ups and final stragglers. Aim and movement keys can be remapped.

Open **Comfort & Controls** from the title or pause menu for saved keyboard remapping, volume, shake intensity, larger text, gentle aim assist, Cozy difficulty, and optional gameplay hints. Controller users can navigate menus and mutation cards with the directional controls and confirm with the standard accept button.

## Build your rat

The first wave-clear draft offers three ways to play:

- **Pinball Rat:** seeds rebound off the fence; Split Decision adds a secondary seed on the rebound.
- **Scurry Menace:** every dash leaves an explosive crumb; Crumb Back refunds 0.4 seconds of recharge when the blast hits.
- **Snack Wizard:** collected treats charge three orbiting seeds; Full Plate raises the orbit to five. Pickup-range upgrades help keep it active.

Later drafts mix stat upgrades with eligible build synergies. Cards show upgrade levels and stat changes; pause to inspect the complete build. Bosses guarantee banked Power and Shield treats plus a bonus mutation draft at wave clear. Leftover treats are banked until the next wave. Full health/shield pickups convert into temporary power, and Triple Seed adds two seeds even to an upgraded weapon.

Encounter recipes alternate bird swarms, cat pincers, ranged sieges, and elite hunts, with short recovery gaps and crowd limits. Yellow attack lines indicate a wind-up; red lines indicate a committed direction. Offscreen indicators reveal attack wind-ups and final stragglers. Shoot the marked fizzy cans to knock nearby enemies away.

The opening birds fall to one accurate seed. Waves grow from 14 enemies to 76 at wave 10 and 110 at wave 15, with up to 42 enemies active in overtime. Fast clears bring the next enemy sooner; brief recovery gaps occur only when the arena is crowded. Raccoons and foxes remain in later encounter recipes. Ranged stragglers approach faster. Dash presses up to 140ms before recharge are buffered, with a recharge meter on the HUD. Once a treat enters pickup range it follows you through a dash. Snack Wizard starts charged, and twelve kills without a treat guarantee a drop (eight in Cozy).

Temporary power comes in bursts: Rapid Claws reduces shot intervals by 32%, Power Nibble adds 35% damage, and both last six seconds. Repeat pickups can bank up to nine seconds, Triple Seed up to ten, and the Wizard orbit up to eight. Spare health or shield treats add two seconds of Power within its cap. Permanent mutations still stack, but tougher enemies and denser waves keep pace. Bosses have substantially more health and attack more often below half health, with their full attack warnings preserved. Cozy reduces crowd sizes and deployment speed as well as enemy speed and damage.

Keep kills within 2.4 seconds to build your streak. A missed beat sheds one multiplier at a time, and reaching x8 grants Rapid Claws once per wave. Your streak survives drafts and intermissions.

Pausing and drafting freeze gameplay and its timers. When all mutations are exhausted, subsequent wave clears award health and score without blocking the run.

## What's in the game

- A 15-wave picnic defense followed by optional endless overtime, with growing crowds, faster deployments, and late-run elite pressure.
- **Birds** weave through the arena at high speed.
- **Cats** stalk, telegraph, pounce, and ricochet off the arena walls.
- **Owls** maintain distance and launch three-feather volleys.
- **Snakes** slither unpredictably, kite the rat, and spit venom.
- **Raccoons** join at wave 6, telegraph, and charge the player.
- **Foxes** arrive at wave 10, circle the player, then telegraph a very fast ambush dash.
- Bosses have three health-based phases, clear attack warnings, and vulnerable recovery windows. The HUD shows their health and phase thresholds.
- All enemy hits go directly to health. Regular enemy health scaling is gentle and capped; pressure comes from larger, faster hordes.
- Rare **elite raiders** have boosted stats, golden badges, and a guaranteed power-up drop.
- Seven enemy drops: healing Cheese, Rapid Claws, Triple Seed, Power Nibble, Sugar Rush, Tin-lid Shield, and Needle Teeth.
- A three-card perk draft after every wave shapes the run with capped multishot, piercing, speed, health, luck, magnetism, and damage upgrades.
- An invulnerable combat dash with dedicated recharge feedback.
- **Light Trail** leaves a glowing, damaging path for three seconds while moving or dashing. It deals 1.5× base bullet damage per second, does not stack at intersections, and is guaranteed as an upgrade choice after wave 2.
- Chain multipliers, wave-clear bonuses, saved high scores, controller support, hit feedback, and a complete title/pause/game-over flow.
- Pickups burst into colored rings and sparks with longer, simple labels. Damage triggers a red edge pulse, health-panel highlight, brighter hit flash, stronger sound, and camera shake; shield blocks have a separate blue effect. Feedback freezes while paused, and damage warnings take priority over pickup pulses.
- A 24×14 meter first-person nightmare garden with a tiled floor, iron fence, watching trees, candlelit altar, and eclipsed moon. The seed blaster recoils when firing; a centered crosshair flashes on hits. Attack paths and ring escape gaps remain visible on the ground. An eclipsed title screen, charcoal menus, and a low ambient drone carry the horror theme through the game.

## Difficulty progression

| Wave | New pressure |
| --- | --- |
| 3 | Ranged owls and elite variants begin appearing. |
| 4 | Venom-spitting snakes join the mix. |
| 5 | Alpha Cat: single pounce → double pounce and sonic ring → triple pounce and denser ring. |
| 6 | Charging raccoons join regular waves. |
| 10 | Fox ambushers and Junkyard Dog: charge → repeated shockwaves → bone trails and three shockwaves. |
| 15 | Barn Owl: aimed fans → sweeping volleys → rotating rings and dives. |
| 20+ | Larger reserves and faster reinforcements, up to 180 active enemies. |

Wave size, active enemy limits, and spawn speed also increase with elapsed play time. Pauses and upgrade choices stop the clock. Boss fights limit active reinforcements to 24 / 30 / 36 across their phases; normal horde pressure resumes when the boss dies.

Story boss health is 1,800 / 2,800 / 4,000. Phases begin at two-thirds and one-third health. Transitions cancel pending attacks without blocking damage, and recovery takes 25% extra damage. Ring attacks leave a visible escape gap. Overtime health increases gently and caps at twice story health.

## Project layout

```text
scenes/main.tscn        Entry scene
scripts/main.gd         Run, wave, spawning, score, and persistence systems
scripts/player.gd       Shared movement, weapon, health, and mutations



scripts/enemy.gd        Enemy movement, damage, and phase transitions
scripts/boss_patterns.gd Boss attack sequences and warnings
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

godot --headless --path . --script tests/playability_test.gd
godot --headless --path . --script tests/keyboard_aim_test.gd
godot --headless --path . --script tests/top_down_test.gd
godot --headless --path . --script tests/balance_test.gd
godot --headless --path . --script tests/fox_model_test.gd
```

Run `godot --path . --script tests/capture_cat_gameplay.gd` to save a top-down gameplay capture to `art/cat/in-game.png`.
Run `godot --path . --script tests/capture_fox_gameplay.gd` to capture the replacement fox in the wave-ten arena at `art/fox/in-game.png`.

Create the browser build after installing Godot's export templates:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

The GitHub Actions workflow runs the gameplay, balance, and sprite test suites, exports the game, and deploys a Pages artifact automatically. `tests/capture_fun_preview.gd` can also be run with the graphical engine to capture title, settings, draft, gameplay, pause, victory, and game-over screenshots in `build/`.

The implementation and regression tests support a first human playtest; they do not establish that a balance choice is more fun. See [FUN_AUDIT.md](FUN_AUDIT.md) for the playtest plan and later experiments such as unlockable kits and shared seeded challenges.

## Contributing

Enemy archetypes, power-ups, juice, accessibility options, audio, and balance passes are all welcome. Keep new runtime dependencies web-compatible and add a focused smoke check when introducing a new system.

## License

[MIT](LICENSE)

Third-party audio is CC0 and documented in [ASSETS.md](ASSETS.md).
