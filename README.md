# Project R.A.T.

[![Test and deploy web game](https://github.com/Inefy/project-rat/actions/workflows/pages.yml/badge.svg)](https://github.com/Inefy/project-rat/actions/workflows/pages.yml)

**Top-down browser game.** Aim around the rat in the nightmare garden, with independent movement and an overhead view of incoming attacks.

**Rodent. Assault. Tactics.** Project R.A.T. is an open-source cartoon survival shooter inspired by the escalating runs of *Vampire Survivors* and the reactive arena combat of *Geometry Wars*. You are a very determined rat defending a backyard picnic from an increasingly ridiculous animal raid. Save the picnic across 15 waves, then choose whether to keep going in endless overtime.

Built with Godot 4.7.2 and designed to run natively in modern desktop browsers.

## Play

**[Play Project R.A.T. in your browser](https://zacbatten.me/project-rat/)**

The latest `main` branch is automatically tested, exported, and deployed to GitHub Pages after every push.

Published engine files and game packs use a unique name for each release so browser caches cannot mix game versions. `build-info.json` identifies the live commit and records asset hashes.

To play locally:

1. Install [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/).
2. Import `project.godot` in the Project Manager.
3. Press **F6** or **F5**.


Enemies, pickups, projectiles, and props use lightweight sprites rendered from the original Blender models. All ten characters have eight movement poses in every facing: alternating steps, moving tails and clothing, wingbeats, or a flowing snake slither. Step rates follow movement speed, and characters lean, crouch, and stretch through attacks and dashes. See `art/movement/README.md` for the animation sources and previews. Movement, collisions, waves, and upgrades run in 2D. Editable models, GLB exports, and the concept sheet are in `art/`; the production guide is `art/README.md`. Combat effects remain procedural. Bundled CC0 Kenney art decorates the backyard; credits are in `ASSETS.md`. No external plug-ins are required to play.

The static 192px sprite sizes below describe the original directional sets. Gameplay characters now use the movement atlases described above, totaling about 5.9 MiB compressed.

The regular cat uses the reference-based black creature with green ring eyes, human-like hands, bloodied fangs, and a curved blade tail. Its eight static 192px directional sprites total 221 KiB. The editable Blender source is `art/cat/reference-cat.blend`; the 407 KiB GLB is retained for editing and reuse and excluded from the top-down browser download.

The fox mixes an MS Paint body with shaded human ears and sleepy eyes: flat orange fill, uneven white brush strokes, a black-dot nose and pink tongue. Its eight Blender-rendered 192px directions total just 43 KiB, 76% smaller than the first shaded version. The editable source is `art/fox/reference-fox.blend`; the 306 KiB GLB is retained for reuse and excluded from the browser download. The replacement keeps the fox's wave-ten arrival, warning, ambush dash, and recovery window. Preview and in-game captures are in `art/fox/`.

The regular owl uses the supplied four-wing design in the same MS Paint + human style: outlined ochre feathers, blank white eyes, a blue beak, forked stick legs, and a shaded human belly button. Its eight 192px directions total 94 KiB. The wings extend in depth to remain readable from the side. Source, preview, and gameplay capture are in `art/owl/`; the GLB stays outside the browser download. The owl retains its wave-three introduction and three-feather attack. Barn Owl keeps its separate boss design.

The snake follows the supplied curled green design with uneven black brush bands, cream patches and red crosses, a shaded human eye, and a glossy forked tongue. Its eight 192px directions total 88 KiB, 63% smaller than the previous snake sprites. Source, preview, and gameplay capture are in `art/snake/`. The 472 KiB GLB stays outside the browser download. Wave-four spawning, slithering, retreat movement, and telegraphed venom attacks remain intact.

The opening-wave bird now uses the supplied bird design with a solid orange body and head, yellow beak, white wings covered in golden eyes, and sculpted human feet. Its eight 192px directions total 84 KiB, 62% smaller than the previous bird sprites. The wings sweep in opposite directions in depth to stay visible when turning. Source, preview, and gameplay capture are in `art/bird/`; the reusable GLB is excluded from the browser package. The bird keeps its weaving movement, collision size and one-seed opening-wave health.

The remaining rat, raccoon, Alpha Cat, Junkyard Dog, and Barn Owl now use the same flat-paint / human-feature style. Their mockups, production sheet, and editable Blender source are in `art/nightmare-cast/`. All seven pickup sprites have been rebuilt, and all sixteen mutation cards have individual Blender-rendered icons. See `art/nightmare-cast/README.md` for rebuilding and validation.

## Demo mode

Choose **Demo mode** on the title screen, enter a starting wave from **1–100** (default **20**), and select **Play wave**. The game rolls a legal upgrade choice for each skipped wave-clear reward, including bonus boss rewards. Wave 20 starts with 22 upgrade picks, full health, and three random temporary treats. Upgrade caps and synergy prerequisites still apply. Pause to inspect the resulting build.

Demo runs continue through the regular encounters and future upgrade drafts. **Retry wave** restarts the same chosen wave with a fresh random build. Practice scores and wave skips do not change personal records.

## Controls

| Action | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | `WASD`, in screen directions | Left stick |
| Aim | Mouse or arrow keys | Right stick |
| Fire | Automatic by default; hold arrow keys, left click or `Space` when disabled | Right stick |
| Dash | `Shift` | Right shoulder |
| Toggle auto-fire | `F` | Right stick click |
| Choose mutation | `1`, `2`, or `3` | Click / tap a card |
| Reroll upgrades (twice per run) | `R` or the Reroll button | Focus the Reroll button and confirm |
| Pause | `P` or `Esc` | Start |

Move with **WASD** and aim at the **mouse cursor**. For keyboard-only play, the **arrow keys** aim in eight directions; holding them also fires. Releasing aim input preserves your direction. **Esc** pauses, showing the menu cursor. Resume restores the aiming reticle. Offscreen indicators reveal incoming attack wind-ups and final stragglers. Aim and movement keys can be remapped.

Open **Comfort & Controls** from the title or pause menu for saved keyboard remapping, volume, shake intensity, larger text, gentle aim assist, Cozy difficulty, and optional gameplay hints. Controller users can navigate menus and mutation cards with the directional controls and confirm with the standard accept button.

## Build your rat

The first wave-clear draft offers three ways to play:

- **Pinball Rat:** seeds rebound off the fence; Split Decision adds a secondary seed on the rebound.
- **Scurry Menace:** every dash leaves an explosive crumb; Crumb Back refunds 0.4 seconds of recharge when the blast hits.
- **Snack Wizard:** collected treats charge three orbiting seeds; Full Plate raises the orbit to five. Pickup-range upgrades help keep it active.

Later drafts mix stat upgrades with eligible build synergies. Cards show upgrade levels and stat changes; pause to inspect the complete build. Bosses guarantee banked Power and Shield treats plus a bonus mutation draft at wave clear. Leftover treats are banked until the next wave. Full health/shield pickups convert into temporary power, and Triple Seed adds two seeds even to an upgraded weapon.

Each run has **two upgrade rerolls**. Rerolls favor choices that were not in the previous offer and preserve the guaranteed wave-two Light Trail. The button is disabled when all eligible upgrades are already shown, including the first draft, so a charge cannot be wasted. Drafts show compatible builds, your current playstyles, and the next enemy introduction or boss.

Encounter recipes alternate bird swarms, cat pincers, ranged sieges, and elite hunts, with short recovery gaps and crowd limits. Yellow attack lines indicate a wind-up; red lines indicate a committed direction. Offscreen indicators reveal attack wind-ups and final stragglers. Shoot the marked fizzy cans to explode them. Their blasts damage both enemies and the rat; new cans appear occasionally, with at most three in the arena.

New enemies arrive at least 440 world units away with a **0.65-second gold ring warning**. They can be shot during the warning, but cannot move, attack, or hurt you until it ends. The warning freezes while paused. After a loss, the result screen identifies the damaging enemy or projectile and gives a specific counter.

The opening birds fall to one accurate seed. Wave populations and active enemy limits increase with wave number and elapsed combat time, with up to 180 enemies active in overtime. Fast clears bring the next enemy sooner; brief recovery gaps occur only when the arena is crowded. Raccoons and foxes remain in later encounter recipes. Ranged stragglers approach faster. Dash presses up to 140ms before recharge are buffered, with a recharge meter on the HUD. Once a treat enters pickup range it follows you through a dash. Snack Wizard starts charged, and twelve kills without a treat guarantee a drop (eight in Cozy).

Temporary power comes in bursts: Rapid Claws reduces shot intervals by 32%, Power Nibble adds 35% damage, and both last six seconds. Repeat pickups can bank up to nine seconds, Triple Seed up to ten, and the Wizard orbit up to eight. Spare health or shield treats add two seconds of Power within its cap. Permanent mutations still stack, but tougher enemies and denser waves keep pace. Bosses have substantially more health and attack more often below half health, with their full attack warnings preserved. Cozy reduces crowd sizes and deployment speed as well as enemy speed and damage.

Keep kills within 2.4 seconds to build your streak. A missed beat sheds one multiplier at a time, and reaching x8 grants Rapid Claws once per wave. Your streak survives drafts and intermissions.

Pausing and drafting freeze gameplay and its timers. When all mutations are exhausted, subsequent wave clears award health and score without blocking the run.

Firing preserves fractional shot timing so fire-rate upgrades and Rapid Claws deliver their intended cadence. A long stall has a bounded catch-up burst, and releasing manual fire never banks extra shots. Defeated enemies immediately free their crowd slot and cannot absorb another seed or consume piercing. Wave clears include deferred last-kill drops before showing and saving the final score; emergency cheese and late drops wait for the next wave even when no upgrades remain. Healing messages show the health actually restored.

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
- A top-down nightmare garden with watching trees, crooked picnic props, visible attack paths, and a low ambient drone. Menus use plain charcoal backgrounds. The title screen states the run's goal and shows your saved best score and wave.

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
godot --headless --path . --script tests/ui_layout_test.gd
godot --headless --path . --script tests/run_improvements_test.gd

godot --headless --path . --script tests/playability_test.gd
godot --headless --path . --script tests/combat_cleanup_test.gd
godot --headless --path . --script tests/light_trail_test.gd
godot --headless --path . --script tests/keyboard_aim_test.gd
godot --headless --path . --script tests/top_down_test.gd
godot --headless --path . --script tests/balance_test.gd
godot --headless --path . --script tests/fox_model_test.gd
godot --headless --path . --script tests/owl_model_test.gd
godot --headless --path . --script tests/snake_model_test.gd
godot --headless --path . --script tests/bird_model_test.gd
godot --headless --path . --script tests/cast_integration_test.gd
```

Run `godot --path . --script tests/capture_cat_gameplay.gd` to save a top-down gameplay capture to `art/cat/in-game.png`.
Run `godot --path . --script tests/capture_fox_gameplay.gd` to capture the replacement fox in the wave-ten arena at `art/fox/in-game.png`.
Run `godot --path . --script tests/capture_owl_gameplay.gd` to capture the four-wing owl and its attack warning at `art/owl/in-game.png`.
Run `godot --path . --script tests/capture_snake_gameplay.gd` to capture the reference snake and its venom warning at `art/snake/in-game.png`.
Run `godot --path . --script tests/capture_bird_gameplay.gd` to capture the many-eyed bird in the opening-wave arena at `art/bird/in-game.png`.
Run `godot --path . --script tests/cast_integration_test.gd` to verify all ten characters and fourteen props through production spawning and save a labeled, staged arena capture to `art/all-models-in-game.png`. This also checks all 94 shipped sprite references and the enemy introductions. The browser uses these lightweight Blender renders for the player, enemies, bosses, pickups and projectiles.

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
