# Veilbound Move Lab

A combat design workspace for **Veilbound**, a Godot 4 fighting game. Define attacks, explore cancel links, and compare combo damage and timing before implementing them in the game.

Use the browser lab to explore timing and damage independently of the game.

## Features

- Editable damage, windup, active time, recovery, and cooldown for up to 40 moves.
- Allowed follow-up links and reorderable combos of up to 20 steps.
- Live phase timelines, total combo damage, duration, damage per second, and cooldown waits.
- Shared-scale move comparison and seconds or approximate 60 fps frame display.
- Browser-local autosave plus validated JSON import/export. Each visitor has their own data; making the site public does not share saved moves between visitors.

## Run locally

No build step or application dependencies are required. From the repository root, open the lab directory and serve its static `dist/` folder:

```sh
cd move-lab
python3 -m http.server 8000 --directory dist
```

Open `http://localhost:8000`. Use an HTTP server rather than opening `index.html` directly because the app uses JavaScript modules.

The seeded Light attack uses confirmed windup 0.08s, active time 0.10s and cooldown 0.4s. Damage 10 HP and recovery 0.18s are clearly labeled estimates. Other moves are examples.

## Model

Cooldown starts at attack input and is tracked independently for each move. A link starts the next move at the end of the current active window, subject to the next move's cooldown. An unlinked move waits for full recovery. Full combo duration includes the last move's recovery. One hit per move; no scaling, hitstun, blockstun or range simulation. Frames are approximate at 60 fps.

## Validation

Run `npm test` from `move-lab/` with Node.js 18 or later. The eight tests verify scheduling, damage, repeated cooldowns, link cancellation, empty/zero states, and import validation. Browser QA covers editing, linking, combo construction, reordering, persistence, comparison, deletion, responsive layout, and JSON backup/restore.

## Source layout

- `dist/index.html` and `dist/styles.css`: responsive workspace and styling.
- `dist/app.js`: editor, move library, combo interactions, and browser persistence.
- `dist/core.js`: pure scheduling calculations and import validation.
- `tests/core.test.js`: scheduling and validation tests using Node's built-in test runner.
