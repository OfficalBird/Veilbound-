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
var stride: float = 0.0
var landing_pose: float = 0.0
var fall_pose: float = 0.0
var sprite_scale: float = 1.0
var ghost_clock: float = 0.0
var ghosts: Array[Dictionary] = []
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
    sprite_scale = 200.0 / cell_height
    sprite.scale = Vector2.ONE * sprite_scale
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
    landing_pose = maxf(0.0, landing_pose - delta)
    if is_defeated: fall_pose = minf(1.0, fall_pose + delta / 0.34)
    for ghost: Dictionary in ghosts:
        ghost.life -= delta
    while not ghosts.is_empty() and float(ghosts.front().life) <= 0.0:
        ghosts.pop_front()
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
            landing_pose = 0.16
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
        _update_visuals(delta)
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
    _update_visuals(delta)
    if dodge_remaining > 0.0:
        ghost_clock -= delta
        if ghost_clock <= 0.0:
            ghost_clock = 0.045
            ghosts.append({"position": position + sprite.position, "frame": sprite.frame,
                "flip": sprite.flip_h, "life": 0.19})
    else:
        ghost_clock = 0.0

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
    stride = 0.0
    landing_pose = 0.0
    fall_pose = 0.0
    ghosts.clear()
    ghost_clock = 0.0
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

func _attack_progress() -> float:
    var duration: float = float(current_attack.get(attack_phase, 0.1))
    return clampf(1.0 - phase_remaining / maxf(duration, 0.001), 0.0, 1.0)

func _update_visuals(delta: float) -> void:
    if not is_instance_valid(sprite): return
    var height: float = 84.0 if fighter_id == "kael" else 88.0
    var stretch := Vector2.ONE
    var offset := Vector2.ZERO
    var tilt := 0.0
    var frame_index := 0
    sprite.flip_h = facing < 0.0
    sprite.modulate = costume_tint
    if is_defeated:
        frame_index = 5
        var fall: float = smoothstep(0.0, 1.0, fall_pose)
        tilt = -facing * fall * 1.15
        offset = Vector2(-facing * 22.0, 38.0) * fall
        sprite.modulate = costume_tint.lerp(Color(0.55, 0.56, 0.67, 0.78), fall)
    elif hitstun_remaining > 0.0:
        frame_index = 5
        var recoil: float = clampf(hitstun_remaining * 3.0, 0.0, 1.0)
        tilt = -facing * 0.17 * recoil
        stretch = Vector2(1.0 + 0.07 * recoil, 1.0 - 0.09 * recoil)
    elif dodge_remaining > 0.0:
        frame_index = 7
        var tuck: float = sin(PI * clampf(dodge_remaining / 0.18, 0.0, 1.0))
        tilt = dodge_direction * 0.28 * tuck
        stretch = Vector2(1.10, 1.0 - 0.21 * tuck)
        sprite.modulate.a = 0.78
    elif blocking:
        frame_index = 6
        tilt = -facing * (0.09 if parry_remaining > 0.0 else 0.02)
        stretch.y = 0.97
    elif is_attacking:
        var progress: float = _attack_progress()
        var kind: String = str(current_attack["kind"])
        var power: float = 1.35 if kind in ["heavy", "burst"] else 1.0
        match attack_phase:
            "windup":
                frame_index = 3
                offset.x = -facing * 9.0 * power * progress
                tilt = -facing * 0.14 * power * progress
                stretch.y = 1.0 - 0.08 * progress
            "active":
                frame_index = 4
                var follow: float = 1.0 - progress * 0.55
                offset.x = facing * 15.0 * power * follow
                tilt = facing * 0.15 * power * follow
                stretch = Vector2(1.0 + 0.08 * follow, 1.0 - 0.05 * follow)
            "recovery":
                frame_index = 4 if progress < 0.48 else 0
                offset.x = facing * 7.0 * (1.0 - progress)
                tilt = facing * 0.08 * (1.0 - progress)
    elif not is_on_floor():
        frame_index = 7
        var rise: float = clampf(-velocity.y / 600.0, -1.0, 1.0)
        stretch = Vector2(1.0 - 0.06 * rise, 1.0 + 0.10 * rise)
        tilt = velocity.x / maxf(move_speed, 1.0) * 0.10
    elif absf(velocity.x) > 15.0:
        stride = fposmod(stride + absf(velocity.x) * delta / 60.0, 1.0)
        frame_index = 1 if stride < 0.5 else 2
        offset.y = -absf(sin(stride * TAU)) * 4.0
        tilt = velocity.x / maxf(move_speed, 1.0) * 0.07
    else:
        stretch.y += sin(age * 3.8) * 0.018
    if is_on_floor() and not is_defeated:
        stretch.y -= landing_pose / 0.16 * 0.13
        stretch.x += landing_pose / 0.16 * 0.08
    sprite.frame = frame_index
    sprite.scale = stretch * sprite_scale
    sprite.rotation = tilt
    sprite.position = Vector2(0.0, -height * stretch.y) + offset
    if flash_remaining > 0.0 and bool(SaveManager.settings["flashes"]):
        sprite.modulate = sprite.modulate.lerp(Color(1.65, 1.65, 1.65), flash_remaining * 8.0)
    queue_redraw()

func _draw() -> void:
    draw_ellipse_shadow()
    for ghost: Dictionary in ghosts:
        var cell := Vector2(floorf(sprite.texture.get_width() / 4.0), floorf(sprite.texture.get_height() / 2.0))
        var frame: int = ghost.frame
        var origin := Vector2(frame % 4, floori(frame / 4.0)) * cell
        var size: Vector2 = cell * sprite_scale
        var center: Vector2 = ghost.position - position
        draw_set_transform(center, 0.0, Vector2(-1.0 if ghost.flip else 1.0, 1.0))
        draw_texture_rect_region(sprite.texture, Rect2(-size * 0.5, size),
            Rect2(origin, cell), Color(accent, float(ghost.life) * 2.3))
    draw_set_transform(Vector2.ZERO)
    if blocking:
        var parrying: bool = parry_remaining > 0.0
        var start: float = -1.3 if facing > 0.0 else 1.85
        var center := Vector2(12.0 * facing, -65.0)
        draw_arc(center, 63.0, start, start + 2.6, 28, Color(accent, 0.16), 9.0, true)
        draw_arc(center, 63.0, start, start + 2.6, 28, Color(accent, 0.85 if parrying else 0.40), 2.0, true)
    if is_attacking:
        _draw_attack()
    if debug_hitboxes:
        draw_rect(Rect2(Vector2(-23, -116), Vector2(46, 116)), Color(0.3, 1, 0.5, 0.5), false)
        if attack_phase == "active": draw_rect(Rect2(get_attack_rect().position - position, get_attack_rect().size), Color(1, 0.3, 0.3, 0.6), false)

func _draw_attack() -> void:
    var kind: String = current_attack["kind"]
    var progress: float = _attack_progress()
    if attack_phase == "windup" and kind in ["heavy", "special", "burst"]:
        var point := Vector2(facing * 46.0, -77.0)
        draw_circle(point, 8.0 + progress * 20.0, Color(accent, progress * 0.14))
        draw_arc(point, 10.0 + progress * 12.0, age * 5.0, age * 5.0 + PI * 1.6,
            26, Color(accent, progress * 0.68), 2.0, true)
    if attack_phase != "active" or kind == "special": return
    var reach: float = current_attack["reach"]
    var upward: bool = kind == "light" and combo_step == 2
    var sweep: float = lerpf(-0.45, 1.15, progress)
    var alpha: float = 1.0 - progress * 0.8
    var outer := PackedVector2Array()
    var ribbon := PackedVector2Array()
    for i: int in range(17):
        var fraction: float = i / 16.0
        var angle: float = sweep - (0.85 + progress * 0.70) * (1.0 - fraction)
        var height: float = sin(angle) * 61.0 * (-1.0 if upward else 1.0)
        outer.append(Vector2(cos(angle) * reach * facing, -67.0 + height))
    ribbon.append_array(outer)
    for i: int in range(16, -1, -1):
        var point: Vector2 = outer[i]
        var taper: float = 0.10 + sin(PI * i / 16.0) * 0.18
        ribbon.append(point.lerp(Vector2(0.0, -67.0), taper))
    draw_colored_polygon(ribbon, Color(accent, alpha * 0.45))
    draw_polyline(outer, Color(accent, alpha * 0.22), 9.0, true)
    draw_polyline(outer, Color(Color.WHITE.lerp(accent, 0.25), alpha), 2.5, true)

func draw_ellipse_shadow() -> void:
    var lift: float = clampf((550.0 - position.y) / 220.0, 0.0, 1.0)
    var floor_offset := Vector2(0.0, maxf(0.0, 550.0 - position.y))
    draw_set_transform(floor_offset, 0.0, Vector2(1.0 - lift * 0.32, 0.23))
    draw_circle(Vector2.ZERO, 39.0, Color(0.02, 0.02, 0.05, 0.18 - lift * 0.10))
    draw_circle(Vector2.ZERO, 28.0, Color(0.02, 0.02, 0.05, 0.32 - lift * 0.21))
    draw_set_transform(Vector2.ZERO)
