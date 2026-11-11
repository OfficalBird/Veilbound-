# Test plan

Run the headless checks documented in the README before gameplay changes. The following manual checks cover presentation, physical input, and release behavior that automated rules tests cannot fully assess.

## Menu and presentation

- Title, fighter selection, controls, credits, and Options open without errors.
- Both portraits fit their cards, including at a reduced window size.
- Both fighters render eight appropriate poses with no atlas bleed.
- Both difficulty and atmosphere selections persist through match startup.
- UI text, health, stamina, Veil, timer, and round markers remain readable.
- Music loops; audio sliders, mute, shake, and flash settings take effect.

## Combat

- Movement stops at arena boundaries; jumping, coyote time, and jump buffering work.
- A late overlap during an active attack can hit, and a swing cannot hit the same target twice.
- Cooldowns, stamina costs, light chaining, and buffered inputs are enforced.
- Front guard applies chip and stamina damage; rear attacks bypass guard.
- A well-timed parry prevents damage and staggers the attacker.
- Exhausted guard breaks; dodge immunity ends after its active window.
- Both sides' projectiles use the same defense rules and expire outside the arena.
- Full Veil enables Veil Break and is consumed by the attack.

## Match flow

- Inputs and damage are locked during round introductions and after K.O.
- Two round wins end a match; timeout uses health ratios; a tie replays the round.
- Arcade progresses through all three rivals and reaches its ending.
- Defeat offers retry; results, pause, and restart can return to the title.
- Training can cycle idle, guard, and active behavior, reset, and recover after defeat.
- Career results are recorded once; settings and records survive restart.

## Input and platforms

- Primary keyboard rebinding and duplicate-key swapping work.
- Esc, R, T, F3, and F11 retain their documented functions.
- A gamepad can navigate menus and perform each combat action.
- Exported builds should be checked on each target OS before distributing them as tested binaries.

## Checks completed for 0.2

- Godot 4.6.3 headless import and startup.
- 36 automated combat, state, and menu checks.
- Browser lab: eight calculation and validation tests, plus interaction checks.
- Native editor visual checks of title, selection, and combat, with keyboard movement and attacks.

Gamepad hardware and macOS/Windows exported binaries require target-device testing.
