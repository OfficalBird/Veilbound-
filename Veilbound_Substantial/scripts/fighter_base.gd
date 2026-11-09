extends CharacterBody2D
class_name FighterBase

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal defeated(fighter: FighterBase)
signal damaged(amount: int, blocked: bool)

@export var max_health: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen_per_second: float = 24.0
@export var block_damage_multiplier: float = 0.25
@export var guard_break_stun: float = 0.55

var health: int
var stamina: float
var blocking := false
var parry_active := false
var invulnerable := false
var is_defeated := false
var hitstun_remaining := 0.0
var _stamina_regen_lock := 0.0
var _parry_generation := 0


func _ready() -> void:
    health = max_health
    stamina = max_stamina
    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, max_stamina)


func _physics_process(delta: float) -> void:
    hitstun_remaining = maxf(0.0, hitstun_remaining - delta)
    _stamina_regen_lock = maxf(0.0, _stamina_regen_lock - delta)

    if not is_defeated and _stamina_regen_lock <= 0.0 and not blocking:
        restore_stamina(stamina_regen_per_second * delta)


func receive_attack(attack: Dictionary, attacker: Node = null) -> bool:
    if is_defeated or invulnerable:
        return false

    var damage := float(attack.get("damage", 10.0))
    var blocked := false
    var blockable := bool(attack.get("blockable", true))

    if blocking and blockable:
        if parry_active:
            restore_stamina(12.0)
            if is_instance_valid(attacker) and attacker.has_method("on_parried"):
                attacker.on_parried(self)
            return false

        blocked = true
        var guard_damage := float(attack.get("guard_damage", maxf(6.0, damage * 0.8)))

        if stamina >= guard_damage:
            spend_stamina(guard_damage)
            damage *= block_damage_multiplier
        else:
            stamina = 0.0
            stamina_changed.emit(stamina, max_stamina)
            blocking = false
            hitstun_remaining = maxf(hitstun_remaining, guard_break_stun)
            damage *= 0.65

    var final_damage := maxi(0, int(round(damage)))
    if final_damage > 0:
        health = maxi(0, health - final_damage)
        health_changed.emit(health, max_health)
        damaged.emit(final_damage, blocked)
        _flash_damage(blocked)

    var knockback := float(attack.get("knockback", 150.0))
    var hitstun := float(attack.get("hitstun", 0.14))

    if blocked:
        knockback *= 0.35
        hitstun *= 0.35

    var away := 1.0
    if is_instance_valid(attacker) and attacker is Node2D:
        away = signf(global_position.x - attacker.global_position.x)
        if away == 0.0:
            away = 1.0

    velocity.x += knockback * away
    hitstun_remaining = maxf(hitstun_remaining, hitstun)

    if health <= 0:
        defeat()

    return final_damage > 0 or blocked


func take_damage(amount: int) -> void:
    receive_attack({"damage": amount, "knockback": 0.0, "hitstun": 0.05}, null)


func spend_stamina(amount: float) -> bool:
    if stamina < amount:
        return false

    stamina = maxf(0.0, stamina - amount)
    _stamina_regen_lock = 0.55
    stamina_changed.emit(stamina, max_stamina)
    return true


func restore_stamina(amount: float) -> void:
    var previous := stamina
    stamina = minf(max_stamina, stamina + amount)
    if not is_equal_approx(previous, stamina):
        stamina_changed.emit(stamina, max_stamina)


func set_blocking(value: bool) -> void:
    blocking = value and stamina > 0.0 and not is_defeated and hitstun_remaining <= 0.0
    if not blocking:
        parry_active = false


func open_parry_window(duration: float = 0.12) -> void:
    _parry_generation += 1
    var generation := _parry_generation
    parry_active = true
    await get_tree().create_timer(duration).timeout
    if generation == _parry_generation:
        parry_active = false


func on_parried(_defender: Node) -> void:
    blocking = false
    parry_active = false
    hitstun_remaining = maxf(hitstun_remaining, 0.5)


func defeat() -> void:
    if is_defeated:
        return

    is_defeated = true
    invulnerable = true
    blocking = false
    parry_active = false
    velocity = Vector2.ZERO
    defeated.emit(self)


func reset_fighter(spawn_position: Vector2) -> void:
    global_position = spawn_position
    velocity = Vector2.ZERO
    health = max_health
    stamina = max_stamina
    blocking = false
    parry_active = false
    invulnerable = false
    is_defeated = false
    hitstun_remaining = 0.0
    _stamina_regen_lock = 0.0
    health_changed.emit(health, max_health)
    stamina_changed.emit(stamina, max_stamina)


func get_health_ratio() -> float:
    return float(health) / float(max_health)


func get_state_name() -> String:
    if is_defeated:
        return "DEFEATED"
    if hitstun_remaining > 0.0:
        return "HITSTUN"
    if blocking:
        return "BLOCK"
    return "IDLE"


func _flash_damage(blocked_hit: bool) -> void:
    var visuals := get_node_or_null("Visuals") as CanvasItem
    if visuals == null:
        return

    visuals.modulate = Color(0.7, 0.85, 1.0) if blocked_hit else Color(1.0, 0.45, 0.45)
    await get_tree().create_timer(0.08).timeout
    if is_instance_valid(visuals):
        visuals.modulate = Color.WHITE
