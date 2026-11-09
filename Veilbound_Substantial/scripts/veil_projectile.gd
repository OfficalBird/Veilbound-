extends Area2D

@export var speed := 520.0
@export var lifetime := 1.8

var direction := 1.0
var owner_fighter: Node
var attack_data := {
    "damage": 12,
    "knockback": 240.0,
    "hitstun": 0.20,
    "guard_damage": 16.0,
    "blockable": true
}


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func setup(new_direction: float, new_owner: Node, tint: Color = Color.WHITE) -> void:
    direction = signf(new_direction)
    owner_fighter = new_owner
    $Visual.modulate = tint
    $Visual.scale.x = direction

    if is_instance_valid(owner_fighter) and owner_fighter is CollisionObject2D:
        var owner_collision := owner_fighter as CollisionObject2D
        collision_mask = 2 if owner_collision.collision_layer == 1 else 1
    else:
        collision_mask = 3


func _physics_process(delta: float) -> void:
    global_position.x += speed * direction * delta
    lifetime -= delta
    if lifetime <= 0.0:
        queue_free()


func _on_body_entered(body: Node) -> void:
    if body == owner_fighter:
        return

    if body.has_method("receive_attack"):
        body.receive_attack(attack_data, owner_fighter)
        queue_free()
