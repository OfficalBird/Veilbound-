extends CharacterBody2D
class_name FighterBase

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal meter_changed(current: float)
signal defeated(fighter: FighterBase)
signal combat_event(kind: String, source: Node, target: Node, amount: int)

const Moves = preload("res://scripts/moves.gd")
const KAEL = preload("res://art/fighters/kael.png")
const NYRA = preload("res://art/fighters/nyra.png")

var fighter_id: String = "kael"
var display_name: String = "KAEL"
var accent: Color = Color("79ded7")
var costume_tint: Color = Color.WHITE
var opponent: FighterBase
var combat_enabled: bool = false
var max_health: int = 100
var health: int = 100
var stamina: float = 100.0
var meter: float = 0.0
var facing: float = 1.0
var move_speed: float = 300.0
var damage_multiplier: float = 1.0
var timing_multiplier: float = 1.0
var is_defeated: bool = false
var is_attacking: bool = false
var blocking: bool = false
var parry_remaining: float = 0.0
var guard_was_held: bool = false
var hitstun_remaining: float = 0.0
var dodge_remaining: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_direction: float = 1.0
var stamina_lock: float = 0.0
var jump_buffer: float = 0.0
var coyote: float = 0.0
var input_buffer: String = ""
var input_buffer_time: float = 0.0
var combo_step: int = 0
var combo_window: float = 0.0
var attack_phase: String = ""
var phase_remaining: float = 0.0
var current_attack: Dictionary = {}
var cooldowns: Dictionary = {"light":0.0,"heavy":0.0,"special":0.0,"burst":0.0}
var hit_targets: Array[Node] = []
var flash_remaining: float = 0.0
var age: float = 0.0
var landing_was_airborne: bool = false
var debug_hitboxes: bool = false
var sprite: Sprite2D
var body_shape: CollisionShape2D

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    body_shape = CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(42, 112)
    body_shape.shape = shape
    body_shape.position = Vector2(0, -56)
    add_child(body_shape)
    sprite = Sprite2D.new()
    sprite.texture = NYRA if fighter_id == "nyra" else KAEL
    sprite.hframes = 4
    sprite.vframes = 2
    var cell_height: float = float(sprite.texture.get_height()) / 2.0
    sprite.scale = Vector2.ONE * (200.0 / cell_height)
    sprite.position = Vector2(0, -84 if fighter_id == "kael" else -88)
    add_child(sprite)
    if fighter_id == "nyra":
        move_speed *= 1.10
        timing_multiplier = 0.92
        damage_multiplier *= 0.94
    reset_fighter(position)

func _read_commands(_delta: float) -> Dictionary:
    return {}

func _physics_process(delta: float) -> void:
    age += delta
    hitstun_remaining = maxf(0.0, hitstun_remaining - delta)
    parry_remaining = maxf(0.0, parry_remaining - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    stamina_lock = maxf(0.0, stamina_lock - delta)
    combo_window = maxf(0.0, combo_window - delta)
    input_buffer_time = maxf(0.0, input_buffer_time - delta)
    flash_remaining = maxf(0.0, flash_remaining - delta)
    for kind: String in cooldowns:
        cooldowns[kind] = maxf(0.0, float(cooldowns[kind]) - delta)
    if combo_window <= 0.0 and not is_attacking:
        combo_step = 0
    if input_buffer_time <= 0.0:
        input_buffer = ""
    if not is_on_floor():
        velocity.y += 1500.0 * delta
        coyote = maxf(0.0, coyote - delta)
        landing_was_airborne = true
    else:
        coyote = 0.10
        if landing_was_airborne:
            combat_event.emit("land", self, null, 0)
            landing_was_airborne = false
    jump_buffer = maxf(0.0, jump_buffer - delta)
    if not is_defeated and stamina_lock <= 0.0 and not blocking:
        stamina = minf(100.0, stamina + 25.0 * delta)
    if is_instance_valid(opponent) and not is_attacking and dodge_remaining <= 0.0:
        var side: float = signf(opponent.position.x - position.x)
        if side != 0.0:
            facing = side
    if is_defeated or not combat_enabled:
        velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
        move_and_slide()
        _update_visuals()
        return
    var commands: Dictionary = _read_commands(delta)
    var direction: float = float(commands.get("move", 0.0))
    if bool(commands.get("jump", false)):
        jump_buffer = 0.13
    for kind: String in ["light", "heavy", "special", "burst"]:
        if bool(commands.get(kind, false)):
            input_buffer = kind
            input_buffer_time = 0.17
    if hitstun_remaining > 0.0:
        blocking = false
        velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
    elif dodge_remaining > 0.0:
        dodge_remaining -= delta
        velocity.x = dodge_direction * 650.0
    else:
        var guard: bool = bool(commands.get("block", false))
        blocking = guard and not is_attacking and stamina > 1.0 and is_on_floor()
        if blocking and not guard_was_held:
            parry_remaining = 0.12
        guard_was_held = guard
        if not blocking:
            parry_remaining = 0.0
        if bool(commands.get("dodge", false)) and not is_attacking and not blocking and dodge_cooldown <= 0.0 and spend_stamina(20.0):
            dodge_direction = signf(direction) if absf(direction) > 0.2 else facing
            dodge_remaining = 0.18
            dodge_cooldown = 0.60
            combat_event.emit("dodge", self, null, 0)
        if jump_buffer > 0.0 and coyote > 0.0 and not is_attacking and not blocking and dodge_remaining <= 0.0:
            velocity.y = -600.0
            jump_buffer = 0.0
            coyote = 0.0
            combat_event.emit("jump", self, null, 0)
        if input_buffer != "" and not blocking and dodge_remaining <= 0.0:
            var cancel: bool = attack_phase == "recovery" and str(current_attack.get("kind", "")) == "light" and combo_step < 3 and input_buffer == "light"
            if (not is_attacking or cancel) and float(cooldowns[input_buffer]) <= 0.0:
                _start_attack(input_buffer)
        if is_attacking or blocking:
            velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
        elif dodge_remaining <= 0.0:
            velocity.x = move_toward(velocity.x, direction * move_speed, 2400.0 * delta)
    _tick_attack(delta)
    move_and_slide()
    position.x = clampf(position.x, 40.0, 1112.0)
    _update_visuals()
    queue_redraw()

func _start_attack(kind: String) -> bool:
    if not combat_enabled or is_defeated or hitstun_remaining > 0.0 or blocking or dodge_remaining > 0.0 or float(cooldowns.get(kind, 0.0)) > 0.0:
        return false
    if is_attacking and not (attack_phase == "recovery" and str(current_attack.get("kind", "")) == "light" and combo_step < 3 and kind == "light"):
        return false
    var next_step: int = combo_step if combo_window > 0.0 and kind == "light" else 0
    if next_step > 2:
        next_step = 0
    var data: Dictionary = Moves.attack(kind, next_step)
    if kind == "burst" and meter < 100.0:
        input_buffer = ""
        return false
    if not spend_stamina(float(data["cost"])):
        input_buffer = ""
        return false
    if kind == "burst":
        meter = 0.0
        meter_changed.emit(meter)
        combat_event.emit("burst", self, opponent, 0)
    combo_step = next_step + 1 if kind == "light" else 0
    combo_window = 0.85
    data["damage"] = int(round(float(data["damage"]) * damage_multiplier))
    for key: String in ["windup", "active", "recovery", "cooldown"]:
        data[key] = float(data[key]) * timing_multiplier
    current_attack = data
    cooldowns[kind] = float(data["cooldown"])
    is_attacking = true
    attack_phase = "windup"
    phase_remaining = float(data["windup"])
    hit_targets.clear()
    input_buffer = ""
    blocking = false
    return true

func _tick_attack(delta: float) -> void:
    if not is_attacking:
        return
    phase_remaining -= delta
    if phase_remaining <= 0.0:
        match attack_phase:
            "windup":
                attack_phase = "active"
                phase_remaining += float(current_attack["active"])
                var kind: String = str(current_attack["kind"])
                combat_event.emit("projectile" if kind == "special" else "swing", self, opponent, int(current_attack["damage"]))
            "active":
                attack_phase = "recovery"
                phase_remaining += float(current_attack["recovery"])
            "recovery":
                cancel_attack()
    if attack_phase == "active" and str(current_attack.get("kind", "")) != "special" and is_instance_valid(opponent) and opponent not in hit_targets:
        if get_attack_rect().intersects(opponent.get_hurt_rect()):
            hit_targets.append(opponent)
            opponent.receive_attack(current_attack, self)

func get_attack_rect() -> Rect2:
    var reach: float = float(current_attack.get("reach", 116.0))
    var x: float = position.x + 15.0 if facing > 0.0 else position.x - reach
    return Rect2(x, position.y - 112.0, reach - 15.0, 100.0)

func get_hurt_rect() -> Rect2:
    return Rect2(position + Vector2(-23, -116), Vector2(46, 116))

func receive_attack(attack: Dictionary, attacker: Node = null) -> bool:
    if is_defeated or dodge_remaining > 0.0 or not combat_enabled:
        return false
    var amount: float = float(attack.get("damage", 10))
    var blocked: bool = false
    var guard_broken: bool = false
    var from_front: bool = not is_instance_valid(attacker) or not attacker is Node2D or signf((attacker as Node2D).position.x - position.x) == facing
    if blocking and from_front:
        if parry_remaining > 0.0:
            parry_remaining = 0.0
            add_meter(20.0)
            stamina = minf(100.0, stamina + 12.0)
            if is_instance_valid(attacker) and attacker.has_method("on_parried"):
                attacker.on_parried(self)
            combat_event.emit("parry", self, attacker, 0)
            return false
        var guard_cost: float = float(attack.get("guard", 12.0))
        blocked = stamina >= guard_cost
        guard_broken = not blocked
        stamina = maxf(0.0, stamina - guard_cost)
        stamina_lock = 0.8
        amount *= 0.20 if blocked else 0.75
    var final_damage: int = maxi(1, int(round(amount)))
    health = maxi(0, health - final_damage)
    health_changed.emit(health, max_health)
    flash_remaining = 0.10
    hitstun_remaining = float(attack.get("hitstun", 0.22)) * (0.4 if blocked else 1.0)
    if guard_broken:
        blocking = false
        hitstun_remaining = 0.75
    if not blocked:
        cancel_attack()
        blocking = false
        parry_remaining = 0.0
        guard_was_held = true
    var away: float = -facing
    if is_instance_valid(attacker) and attacker is Node2D:
        away = signf(position.x - (attacker as Node2D).position.x)
    velocity.x = float(attack.get("knockback", 180.0)) * away * (0.3 if blocked else 1.0)
    add_meter(float(final_damage) * 0.65)
    if is_instance_valid(attacker) and attacker.has_method("add_meter"):
        attacker.add_meter(float(final_damage) * 1.15)
    combat_event.emit("guard_break" if guard_broken else "block" if blocked else "hit", attacker, self, final_damage)
    if health <= 0:
        is_defeated = true
        blocking = false
        cancel_attack()
        defeated.emit(self)
    return true

func on_parried(_defender: Node) -> void:
    cancel_attack()
    blocking = false
    hitstun_remaining = 0.62
    velocity.x = -facing * 180.0

func spend_stamina(amount: float) -> bool:
    if stamina < amount:
        return false
    stamina = maxf(0.0, stamina - amount)
    if amount > 0.0:
        stamina_lock = 0.55
    stamina_changed.emit(stamina, 100.0)
    return true

func add_meter(amount: float) -> void:
    meter = clampf(meter + amount, 0.0, 100.0)
    meter_changed.emit(meter)

func cancel_attack() -> void:
    is_attacking = false
    attack_phase = ""
    hit_targets.clear()

func reset_fighter(spawn: Vector2) -> void:
    position = spawn
    velocity = Vector2.ZERO
    health = max_health
    stamina = 100.0
    is_defeated = false
    blocking = false
    guard_was_held = false
    hitstun_remaining = 0.0
    parry_remaining = 0.0
    dodge_remaining = 0.0
    dodge_cooldown = 0.0
    flash_remaining = 0.0
    input_buffer = ""
    combo_window = 0.0
    combo_step = 0
    cancel_attack()
    for key: String in cooldowns:
        cooldowns[key] = 0.0
    if is_instance_valid(sprite):
        sprite.rotation = 0.0
        sprite.modulate = costume_tint
    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, 100.0)

func get_health_ratio() -> float:
    return float(health) / float(max_health)

func get_state_name() -> String:
    if is_defeated: return "DEFEATED"
    if dodge_remaining > 0.0: return "DODGE"
    if hitstun_remaining > 0.0: return "HITSTUN"
    if blocking: return "PARRY" if parry_remaining > 0.0 else "GUARD"
    if is_attacking: return attack_phase.to_upper()
    if not is_on_floor(): return "AIR"
    return "MOVE" if absf(velocity.x) > 10.0 else "IDLE"

func _update_visuals() -> void:
    if not is_instance_valid(sprite): return
    sprite.flip_h = facing < 0.0
    sprite.modulate = costume_tint
    sprite.position.y = -84.0 if fighter_id == "kael" else -88.0
    sprite.rotation = 0.0
    var frame_index: int = 0
    if is_defeated:
        frame_index = 5
        sprite.rotation = -facing * 0.75
        sprite.position.y = -48.0
        sprite.modulate = Color(0.6, 0.6, 0.7, 0.75)
    elif hitstun_remaining > 0.0:
        frame_index = 5
    elif dodge_remaining > 0.0:
        frame_index = 7
        sprite.modulate.a = 0.48
        sprite.rotation = facing * 0.16
    elif blocking:
        frame_index = 6
    elif is_attacking:
        frame_index = 3 if attack_phase == "windup" else 4
        sprite.position.x = facing * (9.0 if attack_phase == "active" else 0.0)
    elif not is_on_floor():
        frame_index = 7
    elif absf(velocity.x) > 15.0:
        frame_index = 1 + int(age * 10.0) % 2
        sprite.position.y += sin(age * 20.0) * 1.5
    else:
        sprite.position.y += sin(age * 3.5) * 1.0
    if not is_attacking: sprite.position.x = 0.0
    sprite.frame = frame_index
    if flash_remaining > 0.0:
        sprite.modulate = Color(1.8, 1.8, 1.8)
    queue_redraw()

func _draw() -> void:
    draw_ellipse_shadow()
    if blocking:
        var guard_color: Color = accent
        guard_color.a = 0.7 if parry_remaining > 0.0 else 0.25
        draw_arc(Vector2(12 * facing, -65), 63, -1.3 if facing > 0 else 1.85, 1.3 if facing > 0 else 4.45, 28, guard_color, 3.0)
    if attack_phase == "active" and str(current_attack.get("kind", "")) != "special":
        var reach: float = float(current_attack.get("reach", 116.0))
        var points := PackedVector2Array()
        for i: int in range(12):
            var angle: float = -1.15 + float(i) / 11.0 * 2.2
            points.append(Vector2(cos(angle) * reach * facing, -67 + sin(angle) * 64))
        for i: int in range(11, -1, -1):
            var angle: float = -1.15 + float(i) / 11.0 * 2.2
            points.append(Vector2(cos(angle) * reach * 0.78 * facing, -67 + sin(angle) * 45))
        var slash: Color = accent
        slash.a = 0.62
        draw_colored_polygon(points, slash)
        draw_polyline(points.slice(0, 12), Color(0.95, 1.0, 1.0, 0.85), 2.0, true)
    if debug_hitboxes:
        draw_rect(Rect2(Vector2(-23, -116), Vector2(46, 116)), Color(0.3, 1, 0.5, 0.5), false)
        if attack_phase == "active": draw_rect(Rect2(get_attack_rect().position - position, get_attack_rect().size), Color(1, 0.3, 0.3, 0.6), false)

func draw_ellipse_shadow() -> void:
    var points := PackedVector2Array()
    for i: int in range(24):
        points.append(Vector2(cos(float(i)/24.0*TAU)*35, sin(float(i)/24.0*TAU)*7))
    draw_colored_polygon(points, Color(0.02, 0.02, 0.05, 0.48))
