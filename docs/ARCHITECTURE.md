# Architecture

Veilbound uses a command-driven combat layer. `FighterBase` owns movement, hurt rectangles, attack phases, cooldowns, guard, parry, stamina, Veil, animation, and defeat. Player and enemy scripts supply the same command dictionary. This keeps defensive and damage rules consistent across both fighters.

## Deterministic attack lifecycle

Each physics tick updates windup, active time, and recovery. Cooldowns are measured from attack start. During the entire active phase, the hit rectangle is checked against the opponent's hurt rectangle. A per-swing target list prevents repeated damage. Hits, parries, reset, and round end cancel attacks synchronously, so no delayed attack timers can fire during a new round.

Light inputs have a short buffer and a three-step chain. Recovery cancellation is allowed only for another light within the chain, after its cooldown is ready. Move dictionaries live in `moves.gd`; fighter profiles adjust speed and damage.

## Match and menu states

`game.gd` moves through menu, selection, countdown, fight, round-end, and result states. Both fighters reject damage and input during countdowns and results. Arcade advances through three rivals. Training handles defeats by restoring both fighters instead of recording match results.

The game root and HUD process while the scene tree is paused. The arena is explicitly pausable. Hitstop temporarily disables the arena while the game root tracks its expiry; menus and HUD remain independent. Screen shake affects the arena and backdrop without shifting the HUD.

## Presentation and persistence

`stage.gd` draws the backdrop, motes, impacts, and damage numbers. Each fighter chooses a pose from its 4×2 sprite atlas and draws guard arcs and attack trails. `audio_manager.gd` builds short sound effects and a looping original composition at startup. No external audio or runtime network service is required.

`save_manager.gd` uses a version-compatible ConfigFile in Godot's `user://` location. It stores career statistics, accessibility options, audio levels, difficulty, and primary bindings. The font license is retained under `art/fonts/`.

The browser move lab is separate tooling. `.gdignore` excludes it from Godot's resource scanner.
