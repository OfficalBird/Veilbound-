# Veilbound

**Veilbound** is an original 2D pixel-art fighting game prototype built in **Godot 4** with **GDScript**. It began as a basic movement-and-hitbox experiment and has grown into a stateful combat prototype with defensive mechanics, enemy decision-making, rounds, persistence, projectiles, stamina management, combo attacks, and developer tooling.

> Status: active prototype / work in progress. The current art is placeholder pixel art created for the project while the gameplay architecture is developed.

## Why this is more than a tutorial project

The repository is structured as a small game codebase rather than a single-scene demo. Core systems are separated into reusable components, combat is data-driven through attack dictionaries, fighters share a base combat layer, AI uses explicit states and combat decisions, and match flow is managed independently from fighter logic.

## Current gameplay systems

- Pixel-art `AnimatedSprite2D` character rendering
- Left/right movement with acceleration and air control
- Gravity, jump buffering, and coyote time
- Three-hit light combo chain
- Heavy attack with stamina cost
- Blocking with reduced chip damage
- Short parry window when block begins
- Guard stamina damage and guard-break stun
- Directional dodge with temporary invulnerability
- Stamina regeneration and resource costs
- Hit stun and knockback
- Direction-aware melee hitboxes
- Single-hit-per-attack target filtering
- Ranged **Veil Burst** projectile
- Enemy state machine: idle, approach, retreat, attack, block, stunned, defeated
- Enemy light/heavy/ranged attack decisions
- Enemy reactive blocking and parry behavior
- Best-of-three round system
- 60-second round timer and timeout resolution
- Match win/loss state and rematch support
- Player/enemy health and stamina HUD
- Combo indicator, round banner, score, timer, training indicator
- Pause overlay
- Training mode that disables enemy AI
- Runtime debug overlay with fighter states and FPS
- Persistent career match/win counters using `ConfigFile`
- Arena walls and collision boundaries
- Original 4-frame pixel-art idle sheet

## Controls

| Action | Key |
| --- | --- |
| Move | A / D |
| Jump | W |
| Light combo | J |
| Heavy attack | K |
| Block / parry | L |
| Dodge | Shift |
| Veil Burst projectile | I |
| Toggle training AI | T |
| Debug overlay | F3 |
| Pause | Esc |
| Restart match | R |

## Architecture

```text
Veilbound/
├── art/
│   └── player/idle.png
├── scenes/
│   ├── main.tscn
│   └── veil_projectile.tscn
├── scripts/
│   ├── fighter_base.gd       # shared health, stamina, block/parry, hitstun
│   ├── player.gd             # input, movement, combos, dodge, projectile
│   ├── enemy.gd              # combat AI state machine
│   ├── game.gd               # rounds, timer, pause, match flow
│   ├── hud.gd                # UI signal binding and display
│   ├── veil_projectile.gd    # reusable ranged attack
│   ├── input_bootstrap.gd    # runtime action setup
│   └── save_manager.gd       # persistent match statistics
├── docs/
│   ├── ARCHITECTURE.md
│   ├── GAME_DESIGN.md
│   ├── ROADMAP.md
│   └── TEST_PLAN.md
├── CHANGELOG.md
├── LICENSE
├── README.md
└── project.godot
```

## Run locally

1. Install Godot 4.x.
2. Clone this repository.
3. Open Godot Project Manager and import `project.godot`.
4. Run the project.

## Development direction

The current goal is to prove the feel and architecture of combat before investing heavily in final art. Planned work includes more animation states, weapon styles, character-specific movesets, hit sparks, sound design, menus, additional arenas, bosses, progression, accessibility/settings, gamepad remapping, and improved AI personalities.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the larger development plan and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for technical details.
