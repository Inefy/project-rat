# Project R.A.T. — player enjoyment audit

Reviewed September 4, 2026. Scope: current local gameplay, progression, UI, and tests. Findings combine source inspection with a small headless probe using the installed Godot 4.6.2; the README targets 4.7.2. This was not a visual or human playtest. Design benefits below are hypotheses to test, not measured improvements. Existing working changes were left intact.

**Implementation update:** The subsequent implementation addresses pausing and clocks, exhausted drafts, overflow pickups, controller focus/aim, three defining builds and their synergies, encounter recipes, crowd limits, ranged and charge warnings, cleanup indicators, boss rewards, banked treats, combo feedback, death tips, wave-15 victory/overtime, fizzy cans, and saved comfort/control options. Headless regression tests cover the new systems; graphical captures cover the new screens. Human balance testing, optional hold-area cheese stashes, unlockable starting kits/cosmetics, and shared seeded challenges remain future experiments. The findings below describe the pre-change game.

## Main recommendation

Make players feel **“I chose this ridiculous build, learned that enemy, and pulled off that escape.”** The current dash, enemy roster, readable cartoon premise, and quick retry flow are useful foundations. Prioritize reliable controls and rewards, distinct builds, and encounter variety before expanding the enemy roster.

Research links enjoyment to perceived competence, autonomy, and relatedness. Here that suggests understandable failures, meaningful build choices, and eventually shared challenges. It does not establish one recipe that every player will enjoy. [Przybylski, Rigby & Ryan, 2010](https://selfdeterminationtheory.org/SDT/documents/2010_PrzybylskiRigbyRyan_ROGP.pdf).

## 1. Remove frustrations first

| Priority | Evidence | Player consequence | Change |
| --- | --- | --- | --- |
| Immediate | `main.gd:61` uses `PROCESS_MODE_ALWAYS`; gameplay children inherit it. The probe confirmed the player could process and pickup lifetime fell ~0.28 seconds during a ~0.3-second pause. | Pause and the upgrade screen do not reliably suspend the world. | Explicitly make gameplay entities pausable while keeping menu controls responsive. Verify positions, attack states, projectile and pickup lifetimes, and health stay unchanged. |
| Immediate | Buffs, invulnerability, dash recharge, and combo deadlines use `Time.get_ticks_msec()` in `player.gd` and `main.gd`. The probe observed ~295 ms of buff time lost during pause. | Reading cards consumes earned power-up time; a break changes combat state. | Use an active-game clock or pausable countdowns for gameplay durations, independently of the process-mode fix. |
| Immediate | After applying all 47 available upgrade levels, `_open_upgrade_draft()` enters `upgrade`, pauses, and produces zero choices. Confirmed in the probe. | A successful endless run eventually reaches an empty screen it cannot advance through. | Offer a repeatable reward or skip the draft when no upgrades remain. Test the one-, two-, and zero-choice cases. |
| High | `player.gd:119` applies Triple Seed as `max(permanent_projectiles, 3)`. | A player with three or four permanent seeds receives a celebratory pickup that adds no shots. | Give temporary additional seeds up to a safe cap, or convert the pickup to another useful reward. Also handle full-health cheese and full shields explicitly. |
| High | `player.gd:106` falls back to mouse position whenever the aiming stick is released; upgrade cards never explicitly receive initial focus in `hud.gd:362`. | Controller aim can unexpectedly change; card selection needs a full controller-path check. | Remember the last active aiming device and last stick direction. Focus the first card and provide obvious navigation, confirm, and resume controls. |

These are prerequisites for fair evaluation: a player should not dislike a design because an unrelated pause or input defect interferes.

## 2. Give each run a recognizable build

The nine current mutations mainly alter stats, shot count, and piercing. Players can become stronger, but have limited opportunity to invent a strategy.

Prototype three small, coherent paths:

| Build | First noticeable change | Follow-up synergy | Player skill |
| --- | --- | --- | --- |
| Pinball Rat | Acorns ricochet from the fence | A ricochet can split once, with a strict projectile cap | Herd enemies toward useful angles |
| Scurry Menace | Dashing drops an explosive crumb | A successful blast earns a partial dash refund with a cooldown | Time an escape that also sets up damage |
| Snack Wizard | Collected treats charge a short burst of orbiting seeds | A larger pickup radius helps maintain the orbit | Route through rewards under pressure |

Offer one defining choice early, then show compatible upgrades more often without guaranteeing every desired card. Keep straightforward damage and health options. Give cards current-to-new values, upgrade levels, and a short synergy hint; show the actual build in the pause screen instead of only `PERKS xN`.

Test whether players can describe their strategy by the third draft and whether the three paths produce visibly different movement and targeting. Avoid implementing dozens of mutations until these three are fun.

## 3. Build a rhythm of tension and release

`_begin_next_wave()` currently fills a random enemy queue and releases it at one interval for that wave. Enemy health, damage, population, and spawn pressure all increase. That can create escalation without enough contrast.

Try authored encounter recipes using existing enemies: a brief bird swarm, a cat pincer with an escape route, a ranged siege, then an elite hunt. Introduce unfamiliar enemies in a low-pressure encounter before mixing them into a crowd. Use recovery time after peaks and clear announcements before dangerous combinations.

Valve's Left 4 Dead is a precedent for adjusting attack frequency and intensity to shape pacing; it is not evidence that this game needs a complex adaptive AI system. Start with simple encounter recipes and concurrency limits. [Valve's description](https://www.l4d.com/l4d/game.htm).

Keep ordinary enemies satisfying to defeat. Current ordinary health multipliers are 1.00 at wave 1, 2.64 at wave 10, and 5.98 at wave 20. A normal cat consequently rises from 72 to roughly 430 HP. Player upgrades can offset this, so those figures alone do not prove imbalance. Measure actual time to kill across damage, mobility, and sustain builds; shift some late pressure from health inflation into positioning and attack combinations if enemies become tedious.

When only a few enemies remain, provide edge indicators and encourage ranged stragglers to approach. Measure time between the end of the main fight and the draft before deciding how aggressive cleanup assistance should be.

## 4. Make danger understandable and mastery rewarding

Owls can fire within 820 world units, while the nominal viewport is only 720 pixels tall. Their preferred distance can place them above or below the visible area. Ranged attacks are driven by cooldowns without a separate wind-up state. Cats and foxes do telegraph, but their aiming direction keeps tracking until the attack starts.

Add an unmistakable wind-up for ranged attacks, an edge warning for offscreen threats, and a visible committed charge direction shortly before launch. Give players a brief recovery window to punish a missed charge. Preserve the existing character animation and sound personality while keeping danger cues distinguishable from decorative effects.

Track the source of the last damaging hit. Pair the funny game-over headline with something useful: “Caught by a fox dash; step sideways after its charge line locks.” Show a personal improvement such as a new wave record or best clean streak.

Validate by asking players what hit them before giving an explanation. An intelligible loss can invite another attempt; a mysterious one cannot teach the intended skill.

## 5. Make rewards land

Bosses currently receive the normal random drop check; only elites have a guaranteed drop. Give a defeated boss a guaranteed, clearly presented reward, preferably a choice that strengthens the player's build. Clear or neutralize remaining boss projectiles before opening that reward screen.

Provide a safe early power-up encounter so a first-time player experiences the power fantasy without depending on a lucky drop. At wave end, consider collecting remaining rewards automatically and activating temporary buffs when combat resumes.

Move combo feedback into a stable meter with visible decay. At present every kill at combo four or above calls `show_toast`, which also displays pickup information and creates overlapping tweens. Celebrate milestones and let important pickup messages remain readable.

## 6. Make the backyard matter

The picnic and garden props are currently decorative. Prototype one optional interaction: a fizzy can that the player can shoot to knock enemies away. Then test a clearly marked, optional cheese stash that pays out after holding a small area briefly.

These create reasons to change route and memorable escapes. Keep the initial arena open; adding collidable furniture requires navigation and escape-route work because actors currently move without obstacle collision masks. Avoid turning the picnic into a mandatory escort or defense objective before testing whether players enjoy that responsibility.

## 7. Give players a satisfying destination and comfortable controls

Test a finite picnic-defense run ending with the third boss, followed by an explicit choice to enter endless overtime. Tune its duration using observed play sessions. A win gives newcomers closure while preserving the existing survival challenge.

After the core loop works, add unlockable starting kits and cosmetic rat accessories that reward demonstrations of skill. Shared seeded challenges could support friendly comparison, but require consistent randomness beyond the main wave RNG. Multiplayer is a separate, much larger project.

Add saved shake intensity, audio volume, readable UI scaling, remappable controls, and an optional aim assist or slower difficulty. Provide a short, skippable learn-by-doing opening for moving, aiming, and invulnerable dashing. Keep humorous labels alongside plain explanations. Consistent input access, remapping, tutorials, legible text, and difficulty options are supported by [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/basic/).

## Suggested implementation order

1. **Reliability:** pause behavior, gameplay clock, exhausted drafts, ineffective pickups, controller focus and aim.
2. **First prototype:** three defining mutations, early power-up, boss reward, attack warnings, stable combo display.
3. **Pacing:** encounter recipes, cleanup assistance, build-sensitive time-to-kill tuning, finite run with overtime.
4. **Expansion after testing:** one arena interaction, starting-kit unlocks, shared challenges.

The first step is relatively small and has clear correctness checks. The build and pacing prototypes are medium-sized design experiments. New navigation, persistent progression, and shared challenge systems carry greater implementation cost.

## Human playtest plan

Start with 6–10 people split between arena-shooter newcomers and experienced players, including controller users. This is a formative sample for finding problems, not statistical proof. Compare the repaired baseline with one prototype at a time; alternate which version people see first. Use equivalent encounter seeds where practical.

Observe the first session without coaching. Record first damage, first voluntary dash, draft selection time, time to kill, cleanup time, cause of death, chosen upgrades, and whether they voluntarily retry. Ask afterward: “When was it most fun?”, “When were you confused or bored?”, “What would you try next?”, and “Did your choices change how you played?”

Look for repeated confusion, spontaneous laughter or excitement, comprehensible deaths, distinct strategies, and voluntary interest in another run. Treat session length as context, not the objective. A shorter run that feels complete can be a better experience. Retest the strongest changes with fresh players before expanding their scope.
