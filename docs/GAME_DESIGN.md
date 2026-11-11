# Game design

## Core loop

Choose Kael or Nyra, read your rival's spacing, punish unsafe attacks, and win two rounds. Arcade progresses through The Watcher, Sable, and Vesper. The final victory resolves the Three Seals story. Quick Duel provides an immediate match. Training supports idle, guarding, and active opponents with free resets.

## Fighter identities

Kael uses balanced timing and damage. Nyra moves 10% faster, uses 8% shorter move timing, and deals roughly 6% less damage after integer rounding. Rivals use the same combat rules, with health, movement, damage, and decision intervals adjusted by progression and chosen difficulty.

## Moves

| Move | Damage | Windup | Active | Recovery | Cooldown | Stamina |
| --- | --- | --- | --- | --- | --- | --- |
| Quick cut | 10 | 0.08s | 0.10s | 0.18s | 0.40s | 0 |
| Cross cut | 12 | 0.10s | 0.10s | 0.20s | 0.40s | 0 |
| Veil cleaver | 16 | 0.14s | 0.12s | 0.28s | 0.54s | 0 |
| Sundering strike | 26 | 0.24s | 0.14s | 0.36s | 0.78s | 24 |
| Veil bolt | 16 | 0.20s | 0.08s | 0.30s | 0.90s | 30 |
| Veil Break | 42 | 0.34s | 0.18s | 0.45s | 1.40s | Full Veil |

These are Kael's base values. Veil bolt's active phase releases a projectile; its travel time is independent of animation recovery. Cooldowns start when the attack starts. The lab's recovery-cancel model is a design aid; game rules use the data and transitions in `fighter_base.gd`.

## Defense and resources

Guard applies 20% chip damage and consumes stamina when attacked from the front. The initial 0.12s guard window parries, restoring stamina and staggering the attacker. Guard break applies longer stun. Dodge costs 20 stamina, grants 0.18s immunity, and has a 0.60s cooldown. Stamina regenerates after a short lockout. Veil builds from combat; full meter permits the close-range Veil Break.

## Presentation

Moonfall Sanctuary has Moonfall and Ember Dawn atmosphere options. Eclipse Citadel uses a separate gothic arena illustration. The two fighters have separate artwork and eight pose cells each. The interface uses teal, violet, and warm gold; particles, trails, hitstop, damage numbers, sound, and optional shake communicate combat state.

## Scope

This release supports solo play against AI and local two-player versus, keyboard and gamepad input, local settings, and career records. Survival scales one rival per wave, carries health and Veil forward, heals 20 HP per win, and stores a best-wave record. It does not include network play, rollback, a large character roster, or a story campaign outside the three-duel Arcade.
