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

## Local versus and survival

- Choose each P1 and P2 character combination. Verify P2 arrows do not move P1; verify comma, period, slash, Enter, semicolon, and apostrophe.
- Connect two controllers and verify device isolation, including stick, D-pad, and attacks. Hardware gamepad checks require real controllers.
- Verify Options remapping updates P1 in Local Versus and cannot overwrite P2's reserved keys.
- Win as P2 and confirm the result announces Player 2 without changing solo win records.
- Win a Survival wave with reduced health and partial meter. Verify +20 HP, carried meter, stronger rival, and next wave number.
- Lose Survival, verify best completed-shade record persists across restart. Retry and confirm full health, zero meter, wave one.
- Test all arena choices and verify Eclipse Citadel uses its own image and HUD name.
