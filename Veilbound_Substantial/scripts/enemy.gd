extends "res://scripts/fighter_base.gd"

const PROJECTILE_SCENE := preload("res://scenes/veil_projectile.tscn")

enum AIState { IDLE, APPROACH, RETREAT, ATTACK, BLOCK, STUNNED, DEFEATED }

@export var move_speed := 155.0
@export var gravity := 1200.0
@export var preferred_range := 82.0
@export var aggression := 0.72

@onready var player: FighterBase = get_node("../Player")
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_fx: Polygon2D = $AttackHitbox/AttackFX
@onready var visuals: Node2D = $Visuals

var ai_enabled := true
var state: AIState = AIState.IDLE
var facing := -1.0
var can_attack := true
var is_attacking := false
var decision_timer := 0.0
var block_timer := 0.0
var attack_sequence_id := 0


func _ready() -> void:
    super._ready()
    attack_fx.visible = false
    $Visuals/AnimatedSprite2D.play("idle")


func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    decision_timer = maxf(0.0, decision_timer - delta)
    block_timer = maxf(0.0, block_timer - delta)

    if is_defeated:
        state = AIState.DEFEATED
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if not is_instance_valid(player):
        velocity.x = 0.0
        move_and_slide()
        return

    _face_player()

    if hitstun_remaining > 0.0:
        state = AIState.STUNNED
        set_blocking(false)
        velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if block_timer > 0.0:
        state = AIState.BLOCK
        set_blocking(true)
        velocity.x = 0.0
        _apply_gravity(delta)
        move_and_slide()
        return
    elif blocking:
        set_blocking(false)

    if is_attacking:
        state = AIState.ATTACK
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if not ai_enabled:
        state = AIState.IDLE
        velocity.x = 0.0
        _apply_gravity(delta)
        move_and_slide()
        return

    var distance := absf(player.global_position.x - global_position.x)

    if decision_timer <= 0.0:
        decision_timer = 0.22
        _make_combat_decision(distance)

    if state == AIState.APPROACH:
        velocity.x = facing * move_speed
    elif state == AIState.RETREAT:
        velocity.x = -facing * move_speed * 0.72
    else:
        velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)

    _apply_gravity(delta)
    move_and_slide()


func _make_combat_decision(distance: float) -> void:
    if player.has_method("get_state_name") and player.get_state_name() == "ATTACK" and distance < 105.0 and stamina > 10.0:
        if randf() < 0.52:
            _start_block(0.30 + randf() * 0.22)
            return

    if distance > 285.0 and stamina >= 30.0 and randf() < 0.30:
        _special_attack()
        return

    if distance > preferred_range + 28.0:
        state = AIState.APPROACH
        return

    if distance < 52.0 and randf() < 0.45:
        state = AIState.RETREAT
        return

    if distance <= preferred_range + 18.0 and can_attack:
        if stamina >= 22.0 and randf() > aggression:
            _heavy_attack()
        else:
            _light_attack()
    else:
        state = AIState.IDLE


func _start_block(duration: float) -> void:
    state = AIState.BLOCK
    block_timer = duration
    set_blocking(true)
    open_parry_window(0.09)


func _light_attack() -> void:
    _perform_attack({
        "damage": 9,
        "windup": 0.17,
        "active": 0.08,
        "recovery": 0.30,
        "knockback": 175.0,
        "hitstun": 0.16,
        "guard_damage": 10.0
    })


func _heavy_attack() -> void:
    if not spend_stamina(20.0):
        _light_attack()
        return

    _perform_attack({
        "damage": 19,
        "windup": 0.30,
        "active": 0.11,
        "recovery": 0.43,
        "knockback": 400.0,
        "hitstun": 0.33,
        "guard_damage": 24.0
    })


func _special_attack() -> void:
    if not can_attack or not spend_stamina(30.0):
        return

    attack_sequence_id += 1
    var sequence := attack_sequence_id
    can_attack = false
    is_attacking = true
    state = AIState.ATTACK

    await get_tree().create_timer(0.28).timeout
    if sequence != attack_sequence_id or is_defeated or hitstun_remaining > 0.0:
        _finish_attack(sequence)
        return

    var projectile := PROJECTILE_SCENE.instantiate()
    get_parent().add_child(projectile)
    projectile.global_position = global_position + Vector2(58.0 * facing, -12.0)
    projectile.setup(facing, self, Color(1.0, 0.42, 0.42))

    await get_tree().create_timer(0.40).timeout
    _finish_attack(sequence)


func _perform_attack(attack: Dictionary) -> void:
    if not can_attack:
        return

    attack_sequence_id += 1
    var sequence := attack_sequence_id
    can_attack = false
    is_attacking = true
    state = AIState.ATTACK

    await get_tree().create_timer(float(attack["windup"])).timeout
    if sequence != attack_sequence_id or is_defeated or hitstun_remaining > 0.0:
        _finish_attack(sequence)
        return

    attack_fx.visible = true
    await get_tree().physics_frame

    for body in attack_hitbox.get_overlapping_bodies():
        if body == self:
            continue
        if body.has_method("receive_attack"):
            body.receive_attack(attack, self)

    await get_tree().create_timer(float(attack["active"])).timeout
    attack_fx.visible = false
    await get_tree().create_timer(float(attack["recovery"])).timeout
    _finish_attack(sequence)


func _finish_attack(sequence: int) -> void:
    if sequence != attack_sequence_id:
        return
    attack_fx.visible = false
    is_attacking = false
    can_attack = true
    state = AIState.IDLE


func _cancel_attack() -> void:
    attack_sequence_id += 1
    attack_fx.visible = false
    is_attacking = false
    can_attack = true


func receive_attack(attack: Dictionary, attacker: Node = null) -> bool:
    var result := super.receive_attack(attack, attacker)
    if hitstun_remaining > 0.0 and not blocking:
        _cancel_attack()
    return result


func on_parried(defender: Node) -> void:
    super.on_parried(defender)
    _cancel_attack()
    hitstun_remaining = maxf(hitstun_remaining, 0.70)


func _face_player() -> void:
    facing = signf(player.global_position.x - global_position.x)
    if facing == 0.0:
        facing = -1.0
    visuals.scale.x = facing
    attack_hitbox.scale.x = facing


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta


func reset_fighter(spawn_position: Vector2) -> void:
    super.reset_fighter(spawn_position)
    state = AIState.IDLE
    facing = -1.0
    visuals.scale.x = -1.0
    attack_hitbox.scale.x = -1.0
    can_attack = true
    is_attacking = false
    decision_timer = 0.0
    block_timer = 0.0
    attack_sequence_id += 1
    attack_fx.visible = false


func get_state_name() -> String:
    return AIState.keys()[state]
