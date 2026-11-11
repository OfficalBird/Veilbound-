extends "res://scripts/fighter_base.gd"

var difficulty: int = 1
var training_behavior: int = 2
var ai_enabled: bool = true
var decision_timer: float = 0.0
var guard_timer: float = 0.0
var desired_move: float = 0.0
var aggression: float = 0.66
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    super._ready()

func _read_commands(delta: float) -> Dictionary:
    if not ai_enabled or training_behavior == 0:
        return {}
    if training_behavior == 1:
        return {"block":true}
    var commands: Dictionary = {"move":desired_move}
    guard_timer = maxf(0.0, guard_timer - delta)
    commands["block"] = guard_timer > 0.0
    decision_timer -= delta
    if decision_timer > 0.0 or not is_instance_valid(opponent): return commands
    decision_timer = [0.43, 0.26, 0.16][clampi(difficulty, 0, 2)] + rng.randf_range(0.0, 0.12)
    var distance: float = absf(opponent.position.x - position.x)
    desired_move = facing if distance > 114.0 else -facing * 0.5 if distance < 58.0 else 0.0
    if opponent.is_attacking and distance < 185.0 and rng.randf() < (0.22 + 0.15 * difficulty):
        guard_timer = rng.randf_range(0.22, 0.45)
        commands["block"] = true
    elif distance < 170.0 and meter >= 100.0 and rng.randf() < 0.65:
        commands["burst"] = true
    elif distance > 270.0 and stamina > 32.0 and rng.randf() < 0.42:
        commands["special"] = true
    elif distance < 146.0 and rng.randf() < aggression:
        commands["heavy" if stamina > 30.0 and rng.randf() < 0.26 else "light"] = true
    elif distance < 90.0 and rng.randf() < 0.20 and difficulty > 0:
        commands["dodge"] = true
        desired_move = -facing
    if opponent.position.y < position.y - 60.0 and rng.randf() < 0.25:
        commands["jump"] = true
    commands["move"] = desired_move
    return commands

func reset_fighter(spawn: Vector2) -> void:
    super.reset_fighter(spawn)
    decision_timer = 0.25
    desired_move = 0.0
    guard_timer = 0.0
