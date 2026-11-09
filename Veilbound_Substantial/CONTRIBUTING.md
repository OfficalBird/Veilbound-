# Contributing / Development Notes

Veilbound is currently primarily maintained as an independent project. If changes are proposed, keep gameplay systems modular and avoid putting match flow or UI manipulation directly into fighter scripts.

Before submitting a change:

1. Run the manual checks in `docs/TEST_PLAN.md`.
2. Keep new actions configurable rather than hard-coding repeated key checks.
3. Put shared fighter behavior in `fighter_base.gd` when both player and AI need it.
4. Document new combat mechanics in `docs/GAME_DESIGN.md`.
