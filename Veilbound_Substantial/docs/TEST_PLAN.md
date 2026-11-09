# Manual Test Plan

Use this list after gameplay changes.

## Movement
- Player moves left/right and cannot pass arena walls.
- Jump works from the floor.
- Jump input shortly before landing is buffered.
- Walking off a ledge still allows a brief coyote-time jump.

## Combat
- Light attack cycles through three combo steps when timed within the combo window.
- Heavy attack consumes stamina and cannot be used without enough stamina.
- Melee attacks do not damage their owner.
- A single melee swing cannot damage the same target multiple times.
- Knockback pushes away from the attacker.

## Defense
- Holding block reduces incoming damage.
- Blocking consumes stamina when hit.
- Pressing block just before impact can parry.
- Parried attacker enters hitstun.
- Dodge consumes stamina and ignores attacks during the invulnerability window.

## Projectile
- Player projectile damages enemy but not player.
- Enemy projectile damages player but not enemy.
- Projectile expires after its lifetime.

## AI
- Enemy approaches at long range.
- Enemy can retreat at very close range.
- Enemy attacks in range.
- Enemy sometimes blocks when the player attacks.
- Training toggle disables AI movement/attacks.

## Match flow
- Defeating a fighter ends the round.
- Timeout awards the round to the fighter with higher health percentage.
- Best-of-three match ends at two round wins.
- R restarts the match.
- Esc pauses and resumes gameplay.
- Match statistics persist after restarting the application.
