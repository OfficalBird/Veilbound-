extends CharacterBody2D

var health = 100
var speed = 120.0
var gravity = 1200.0
var attack_range = 80.0
var attack_damage = 10
var can_attack = true
var attack_cooldown = 1.0

@onready var health_bar = $"../UI/EnemyHealthBar"
@onready var player = get_node("../Player")


func _physics_process(delta):
    if not is_instance_valid(player):
        velocity.x = 0
        move_and_slide()
        return

    var face_direction = sign(player.global_position.x - global_position.x)
    $Polygon2D.scale.x = face_direction

    if not is_on_floor():
        velocity.y += gravity * delta

    var distance = global_position.distance_to(player.global_position)

    if distance > attack_range:
        move_toward_player()
    else:
        velocity.x = 0
        attack_player()

    move_and_slide()


func move_toward_player():
    var direction = sign(player.global_position.x - global_position.x)
    velocity.x = direction * speed


func attack_player():
    if not can_attack or not is_instance_valid(player):
        return

    can_attack = false
    print("Enemy attacks!")

    if global_position.distance_to(player.global_position) <= attack_range:
        player.take_damage(attack_damage)

    await get_tree().create_timer(attack_cooldown).timeout
    can_attack = true


func take_damage(amount):
    health -= amount
    health_bar.value = health
    print("Enemy health: ", health)

    if health <= 0:
        die()


func die():
    print("Enemy defeated!")
    queue_free()
