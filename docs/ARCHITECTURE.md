# Veilbound Architecture

## Design goals

The prototype separates **match flow**, **fighter rules**, **player input**, **enemy decision-making**, and **UI** so each can evolve without turning `player.gd` into a monolithic script.

## FighterBase

`fighter_base.gd` owns rules shared by every combatant:

- health and defeat state
- stamina and regeneration
- blocking and chip damage
- parry windows
- guard damage / guard break
- knockback and hitstun
- reusable combat signals
- round reset behavior

Attacks are passed as dictionaries. This keeps damage, windup, active time, recovery, knockback, hitstun, and guard pressure configurable without creating a separate function for every move.

## Player

`player.gd` adds input-specific behavior:

- acceleration and air control
- jump buffer + coyote time
- facing direction
- light combo sequencing
- heavy attack stamina spending
- dodge invulnerability
- block/parry input
- ranged Veil Burst
- attack cancellation when interrupted

## Enemy AI

`enemy.gd` uses an explicit state enum. It makes short-interval decisions based on distance, player attack state, stamina, and randomness. The intent is to make the enemy readable rather than perfectly optimal.

## Match controller

`game.gd` owns the match instead of either fighter:

- round timer
- score
- best-of-three logic
- timeout decisions
- resets
- pause
- training toggle
- debug overlay data
- persistent win recording

## HUD

`hud.gd` listens to fighter signals. Fighters do not directly reach into UI nodes to change bars, keeping combat code independent from layout.

## Persistence

`save_manager.gd` stores simple career counters with Godot `ConfigFile` in `user://veilbound_save.cfg`.

## Collision layers

- Layer 1: Player body
- Layer 2: Enemy body
- Layer 4: World / arena
- Layer 8: Projectile areas

Player melee hitboxes only scan the enemy layer and enemy hitboxes only scan the player layer. Projectiles set their target mask dynamically based on their owner.
