# Veilbound

Veilbound is an early 2D pixel-art fighting game prototype being built in Godot 4.

## Current prototype

- A / D movement
- W jump
- J light attack
- K reserved for heavy attack
- L reserved for block
- Directional player attack hitbox
- Attack wind-up / cooldown timing
- Enemy chase-and-attack AI
- Player and enemy health
- Health bars
- Player death / enemy death
- Four-frame 48x64 pixel-art idle animation

## Engine

Built with Godot 4.x using GDScript.

## Run locally

1. Install Godot 4.x.
2. Clone/download this repository.
3. In the Godot Project Manager, click **Import**.
4. Select `project.godot`.
5. Open the project and run `main.tscn`.

## Project layout

```text
Veilbound/
├── art/
│   └── player/
│       └── idle.png
├── .gitattributes
├── .gitignore
├── README.md
├── project.godot
├── main.tscn
├── player.gd
└── enemy.gd
```

## Controls

| Action | Key |
| --- | --- |
| Move left | A |
| Move right | D |
| Jump | W |
| Light attack | J |
| Heavy attack | K (reserved) |
| Block | L (reserved) |

## Development status

This is a learning/prototype build. The next planned systems are additional animation states, proper attack animations, hurt reactions, heavier combat mechanics, improved enemy AI, weapons, and arena art.

## Art

The current player idle sprite sheet is a four-frame horizontal sheet with 48x64 frames.
