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
        var fade: float = 1.0 - float(i) / 8.0
        var point: Vector2 = trail[i] - position
        draw_circle(point, 14.0 * fade, Color(tint, fade * 0.14))
        draw_circle(point, 6.0 * fade, Color(tint, fade * 0.44))
        var spiral: float = sin(age * 32.0 - i * 0.9)
        draw_circle(point + Vector2(0, spiral * 15.0 * fade), 2.0, Color(tint, fade * 0.70))
    draw_circle(Vector2.ZERO, 19.0, Color(tint, 0.19))
    var blade := PackedVector2Array([
        Vector2(-28.0 * direction, 0.0),
        Vector2(-6.0 * direction, -8.0),
        Vector2(22.0 * direction, 0.0),
        Vector2(-6.0 * direction, 8.0),
    ])
    draw_colored_polygon(blade, tint)
    draw_line(Vector2(-14.0 * direction, 0.0), Vector2(17.0 * direction, 0.0),
        Color.WHITE.lerp(tint, 0.2), 3.0, true)
