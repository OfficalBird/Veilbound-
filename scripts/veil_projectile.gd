extends Node2D

var direction: float = 1.0
var owner_fighter: FighterBase
var target: FighterBase
var tint: Color = Color.CYAN
var age: float = 0.0
var trail: Array[Vector2] = []
var attack_data: Dictionary = {}

func _physics_process(delta: float) -> void:
    age += delta
    position.x += direction * 560.0 * delta
    trail.push_front(position)
    if trail.size() > 8: trail.pop_back()
    if is_instance_valid(target) and Rect2(position - Vector2(18, 15), Vector2(36, 30)).intersects(target.get_hurt_rect()):
        target.receive_attack(attack_data, owner_fighter)
        queue_free()
    if age > 2.0 or position.x < -60.0 or position.x > 1212.0:
        queue_free()
    queue_redraw()

func _draw() -> void:
    for i: int in range(trail.size()):
        var color: Color = tint
        color.a = (1.0-float(i)/8.0)*0.3
        draw_circle(trail[i] - position, 11.0-float(i), color)
    draw_circle(Vector2.ZERO, 15, Color(tint, 0.15))
    draw_colored_polygon(PackedVector2Array([Vector2(-24*direction,0),Vector2(0,-10),Vector2(22*direction,0),Vector2(0,10)]), tint)
    draw_line(Vector2(-10*direction,0),Vector2(15*direction,0),Color.WHITE,3)
