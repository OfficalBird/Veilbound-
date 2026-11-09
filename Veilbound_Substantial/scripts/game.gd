extends Node2D

@export var round_time := 60.0
@export var rounds_to_win := 2

@onready var player = $Player
@onready var enemy = $Enemy
@onready var hud = $UI

const PLAYER_SPAWN := Vector2(280, 500)
const ENEMY_SPAWN := Vector2(872, 500)

var current_round := 1
var player_score := 0
var enemy_score := 0
var time_remaining := 60.0
var round_active := false
var match_over := false
var training_mode := false
var debug_visible := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    player.defeated.connect(_on_fighter_defeated)
    enemy.defeated.connect(_on_fighter_defeated)
    hud.bind_fighters(player, enemy)
    hud.set_persistent_stats(SaveManager.total_match_wins, SaveManager.total_matches_played)
    await get_tree().create_timer(0.35).timeout
    _begin_round()


func _process(delta: float) -> void:
    if round_active and not get_tree().paused:
        time_remaining = maxf(0.0, time_remaining - delta)
        hud.set_timer(time_remaining)
        if time_remaining <= 0.0:
            _resolve_timeout()

    if debug_visible:
        hud.set_debug_text(
            "PLAYER: %s | HP %d | ST %.0f\nENEMY: %s | HP %d | ST %.0f\nFPS: %d" % [
                player.get_state_name(), player.health, player.stamina,
                enemy.get_state_name(), enemy.health, enemy.stamina,
                Engine.get_frames_per_second()
            ]
        )


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return

    match event.physical_keycode:
        KEY_ESCAPE:
            _toggle_pause()
        KEY_R:
            restart_match()
        KEY_T:
            training_mode = not training_mode
            enemy.ai_enabled = not training_mode
            hud.set_training(training_mode)
        KEY_F3:
            debug_visible = not debug_visible
            hud.set_debug_visible(debug_visible)


func _begin_round() -> void:
    get_tree().paused = false
    hud.set_pause_visible(false)
    match_over = false
    round_active = false
    time_remaining = round_time

    player.reset_fighter(PLAYER_SPAWN)
    enemy.reset_fighter(ENEMY_SPAWN)
    enemy.ai_enabled = not training_mode

    hud.set_round(current_round)
    hud.set_score(player_score, enemy_score)
    hud.set_timer(time_remaining)
    hud.set_message("ROUND %d" % current_round)
    await get_tree().create_timer(0.75).timeout
    hud.set_message("FIGHT!")
    await get_tree().create_timer(0.45).timeout
    hud.set_message("")
    round_active = true


func _on_fighter_defeated(fighter: FighterBase) -> void:
    if not round_active:
        return

    if fighter == enemy:
        _end_round(player)
    else:
        _end_round(enemy)


func _resolve_timeout() -> void:
    if not round_active:
        return

    if is_equal_approx(player.get_health_ratio(), enemy.get_health_ratio()):
        _end_round(null)
    elif player.get_health_ratio() > enemy.get_health_ratio():
        _end_round(player)
    else:
        _end_round(enemy)


func _end_round(winner: FighterBase) -> void:
    round_active = false

    if winner == player:
        player_score += 1
        hud.set_message("PLAYER WINS ROUND")
    elif winner == enemy:
        enemy_score += 1
        hud.set_message("ENEMY WINS ROUND")
    else:
        hud.set_message("DRAW")

    hud.set_score(player_score, enemy_score)

    if player_score >= rounds_to_win or enemy_score >= rounds_to_win:
        match_over = true
        var player_won := player_score > enemy_score
        SaveManager.record_match(player_won)
        hud.set_persistent_stats(SaveManager.total_match_wins, SaveManager.total_matches_played)
        await get_tree().create_timer(1.0).timeout
        hud.set_message("VICTORY - PRESS R TO REMATCH" if player_won else "DEFEAT - PRESS R TO REMATCH")
        return

    await get_tree().create_timer(1.5).timeout
    current_round += 1
    _begin_round()


func restart_match() -> void:
    get_tree().paused = false
    hud.set_pause_visible(false)
    player_score = 0
    enemy_score = 0
    current_round = 1
    match_over = false
    _begin_round()


func _toggle_pause() -> void:
    if match_over:
        return
    get_tree().paused = not get_tree().paused
    hud.set_pause_visible(get_tree().paused)
