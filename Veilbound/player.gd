extends CharacterBody2D

var health = 100

var can_attack = true
var attack_cooldown = 0.4
var attack_windup = 0.08
var attack_active_time = 0.10

var speed = 300.0
var jump_velocity = -500.0
var gravity = 1200.0

@onready var health_bar = $"../UI/PlayerHealthBar"
@onready var attack_hitbox = $AttackHitbox
@onready var animated_sprite = $Visuals/AnimatedSprite2D


func _ready():
    _ensure_input_actions()
    animated_sprite.play("idle")


func _physics_process(delta):
    var direction = Input.get_axis("move_left", "move_right")

    velocity.x = direction * speed

    if direction != 0:
        var facing = sign(direction)
        $Visuals.scale.x = facing
        $AttackHitbox.scale.x = facing

    if not is_on_floor():
        velocity.y += gravity * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    if Input.is_action_just_pressed("light_attack"):
        light_attack()

    move_and_slide()


func light_attack():
    if not can_attack:
        return

    can_attack = false
    print("Punch Started")

    # Wind-up before the hit is checked.
    await get_tree().create_timer(attack_windup).timeout
    await get_tree().physics_frame

    var bodies = attack_hitbox.get_overlapping_bodies()
    print("Bodies in hitbox: ", bodies.size())

    for body in bodies:
        if body != self and body.has_method("take_damage"):
            body.take_damage(10)

    # Active and recovery timing for the prototype attack.
    await get_tree().create_timer(attack_active_time).timeout
    await get_tree().create_timer(
        attack_cooldown - attack_windup - attack_active_time
    ).timeout

    can_attack = true


func take_damage(amount):
    health -= amount
    health_bar.value = health
    print("Player health: ", health)

    if health <= 0:
        die()


func die():
    print("Player defeated!")
    queue_free()


func _ensure_input_actions():
    _ensure_key_action("move_left", KEY_A)
    _ensure_key_action("move_right", KEY_D)
    _ensure_key_action("jump", KEY_W)
    _ensure_key_action("light_attack", KEY_J)
    _ensure_key_action("heavy_attack", KEY_K)
    _ensure_key_action("block", KEY_L)


func _ensure_key_action(action_name: StringName, keycode):
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    if InputMap.action_get_events(action_name).is_empty():
        var event = InputEventKey.new()
        event.physical_keycode = keycode
        InputMap.action_add_event(action_name, event)
