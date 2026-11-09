extends "res://scripts/fighter_base.gd"

signal combo_changed(step: int)

const PROJECTILE_SCENE := preload("res://scenes/veil_projectile.tscn")

@export var move_speed := 300.0
@export var air_control := 0.82
@export var jump_velocity := -500.0
@export var gravity := 1200.0
@export var dodge_speed := 620.0
@export var dodge_duration := 0.16

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_fx: Polygon2D = $AttackHitbox/AttackFX
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

var facing := 1.0
var can_attack := true
var is_attacking := false
var is_dodging := false
var combo_step := 0
var combo_timer := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var dodge_timer := 0.0
var dodge_cooldown := 0.0
var attack_sequence_id := 0


func _ready() -> void:
    super._ready()
    animated_sprite.play("idle")
    attack_fx.visible = false


func _physics_process(delta: float) -> void:
    super._physics_process(delta)

    combo_timer = maxf(0.0, combo_timer - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)

    if combo_timer <= 0.0 and combo_step != 0:
        combo_step = 0
        combo_changed.emit(combo_step)

    if is_defeated:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if is_dodging:
        dodge_timer -= delta
        velocity.x = facing * dodge_speed
        _apply_gravity(delta)
        move_and_slide()
        if dodge_timer <= 0.0:
            is_dodging = false
            invulnerable = false
        return

    _update_jump_windows(delta)

    if hitstun_remaining > 0.0:
        set_blocking(false)
        velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    _handle_defense_and_attacks()
    _handle_movement(delta)
    _apply_gravity(delta)
    _try_buffered_jump()
    move_and_slide()


func _handle_movement(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")

    if direction != 0.0:
        facing = signf(direction)
        visuals.scale.x = facing
        attack_hitbox.scale.x = facing

    if is_attacking or blocking:
        velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
        return

    var target_speed := direction * move_speed
    var control := 1.0 if is_on_floor() else air_control
    velocity.x = move_toward(velocity.x, target_speed, move_speed * 10.0 * control * delta)


func _handle_defense_and_attacks() -> void:
    if Input.is_action_just_pressed("block") and not is_attacking:
        set_blocking(true)
        open_parry_window(0.12)

    if Input.is_action_just_released("block"):
        set_blocking(false)

    if blocking:
        if not Input.is_action_pressed("block"):
            set_blocking(false)
        return

    if Input.is_action_just_pressed("dodge"):
        _start_dodge()
        if is_dodging:
            return

    if Input.is_action_just_pressed("light_attack"):
        light_attack()
    elif Input.is_action_just_pressed("heavy_attack"):
        heavy_attack()
    elif Input.is_action_just_pressed("special_attack"):
        special_attack()


func _update_jump_windows(delta: float) -> void:
    if is_on_floor():
        coyote_timer = 0.11
    else:
        coyote_timer = maxf(0.0, coyote_timer - delta)

    if Input.is_action_just_pressed("jump"):
        jump_buffer_timer = 0.12
    else:
        jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)


func _try_buffered_jump() -> void:
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not is_attacking and not blocking:
        velocity.y = jump_velocity
        jump_buffer_timer = 0.0
        coyote_timer = 0.0


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta


func _start_dodge() -> void:
    if is_dodging or dodge_cooldown > 0.0 or is_attacking or blocking:
        return
    if not spend_stamina(20.0):
        return

    is_dodging = true
    invulnerable = true
    dodge_timer = dodge_duration
    dodge_cooldown = 0.45
    velocity.x = facing * dodge_speed


func light_attack() -> void:
    if not can_attack or is_dodging or blocking:
        return

    if combo_timer > 0.0:
        combo_step = (combo_step % 3) + 1
    else:
        combo_step = 1

    combo_timer = 0.62
    combo_changed.emit(combo_step)

    var attacks := [
        {"damage": 8, "windup": 0.06, "active": 0.07, "recovery": 0.16, "knockback": 120.0, "hitstun": 0.11, "guard_damage": 7.0},
        {"damage": 10, "windup": 0.07, "active": 0.08, "recovery": 0.17, "knockback": 155.0, "hitstun": 0.13, "guard_damage": 9.0},
        {"damage": 14, "windup": 0.10, "active": 0.09, "recovery": 0.25, "knockback": 330.0, "hitstun": 0.25, "guard_damage": 14.0}
    ]

    _perform_melee_attack(attacks[combo_step - 1])


func heavy_attack() -> void:
    if not can_attack or is_dodging or blocking:
        return
    if not spend_stamina(24.0):
        return

    combo_step = 0
    combo_timer = 0.0
    combo_changed.emit(combo_step)
    _perform_melee_attack({
        "damage": 24,
        "windup": 0.22,
        "active": 0.12,
        "recovery": 0.38,
        "knockback": 460.0,
        "hitstun": 0.38,
        "guard_damage": 28.0
    })


func special_attack() -> void:
    if not can_attack or is_dodging or blocking:
        return
    if not spend_stamina(35.0):
        return

    attack_sequence_id += 1
    var sequence := attack_sequence_id
    can_attack = false
    is_attacking = true
    velocity.x *= 0.3

    await get_tree().create_timer(0.18).timeout
    if sequence != attack_sequence_id or is_defeated or hitstun_remaining > 0.0:
        _finish_attack(sequence)
        return

    var projectile := PROJECTILE_SCENE.instantiate()
    get_parent().add_child(projectile)
    projectile.global_position = global_position + Vector2(58.0 * facing, -12.0)
    projectile.setup(facing, self, Color(0.45, 0.75, 1.0))

    await get_tree().create_timer(0.28).timeout
    _finish_attack(sequence)


func _perform_melee_attack(attack: Dictionary) -> void:
    attack_sequence_id += 1
    var sequence := attack_sequence_id
    can_attack = false
    is_attacking = true
    set_blocking(false)
    velocity.x *= 0.25

    await get_tree().create_timer(float(attack["windup"])).timeout
    if sequence != attack_sequence_id or is_defeated or hitstun_remaining > 0.0:
        _finish_attack(sequence)
        return

    attack_fx.visible = true
    await get_tree().physics_frame

    var already_hit: Array[Node] = []
    for body in attack_hitbox.get_overlapping_bodies():
        if body == self or body in already_hit:
            continue
        if body.has_method("receive_attack"):
            already_hit.append(body)
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
    hitstun_remaining = maxf(hitstun_remaining, 0.62)


func reset_fighter(spawn_position: Vector2) -> void:
    super.reset_fighter(spawn_position)
    facing = 1.0
    visuals.scale.x = 1.0
    attack_hitbox.scale.x = 1.0
    can_attack = true
    is_attacking = false
    is_dodging = false
    combo_step = 0
    combo_timer = 0.0
    dodge_timer = 0.0
    dodge_cooldown = 0.0
    attack_sequence_id += 1
    attack_fx.visible = false
    combo_changed.emit(combo_step)


func get_state_name() -> String:
    if is_defeated:
        return "DEFEATED"
    if is_dodging:
        return "DODGE"
    if hitstun_remaining > 0.0:
        return "HITSTUN"
    if blocking:
        return "BLOCK/PARRY" if parry_active else "BLOCK"
    if is_attacking:
        return "ATTACK"
    if not is_on_floor():
        return "AIR"
    if absf(velocity.x) > 5.0:
        return "MOVE"
    return "IDLE"
