extends CanvasLayer

@onready var player_health: ProgressBar = $TopBar/PlayerHealth
@onready var enemy_health: ProgressBar = $TopBar/EnemyHealth
@onready var player_stamina: ProgressBar = $TopBar/PlayerStamina
@onready var enemy_stamina: ProgressBar = $TopBar/EnemyStamina
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var round_label: Label = $TopBar/RoundLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var message_label: Label = $MessageLabel
@onready var combo_label: Label = $ComboLabel
@onready var training_label: Label = $TrainingLabel
@onready var wins_label: Label = $WinsLabel
@onready var debug_label: Label = $DebugLabel
@onready var pause_overlay: ColorRect = $PauseOverlay

var debug_visible := false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    pause_overlay.visible = false
    message_label.text = ""
    combo_label.text = ""
    training_label.text = ""
    debug_label.visible = false


func bind_fighters(player: FighterBase, enemy: FighterBase) -> void:
    player.health_changed.connect(_on_player_health_changed)
    player.stamina_changed.connect(_on_player_stamina_changed)
    enemy.health_changed.connect(_on_enemy_health_changed)
    enemy.stamina_changed.connect(_on_enemy_stamina_changed)

    if player.has_signal("combo_changed"):
        player.connect("combo_changed", Callable(self, "_on_combo_changed"))

    _on_player_health_changed(player.health, player.max_health)
    _on_player_stamina_changed(player.stamina, player.max_stamina)
    _on_enemy_health_changed(enemy.health, enemy.max_health)
    _on_enemy_stamina_changed(enemy.stamina, enemy.max_stamina)


func set_timer(seconds: float) -> void:
    timer_label.text = "%02d" % int(ceil(seconds))


func set_round(round_number: int) -> void:
    round_label.text = "ROUND %d" % round_number


func set_score(player_score: int, enemy_score: int) -> void:
    score_label.text = "%d  -  %d" % [player_score, enemy_score]


func set_message(text: String) -> void:
    message_label.text = text


func set_training(enabled: bool) -> void:
    training_label.text = "TRAINING: AI OFF" if enabled else ""


func set_pause_visible(visible: bool) -> void:
    pause_overlay.visible = visible


func set_persistent_stats(wins: int, matches: int) -> void:
    wins_label.text = "Career wins: %d   Matches: %d" % [wins, matches]


func set_debug_visible(visible: bool) -> void:
    debug_visible = visible
    debug_label.visible = visible


func set_debug_text(text: String) -> void:
    if debug_visible:
        debug_label.text = text


func _on_player_health_changed(current: int, maximum: int) -> void:
    player_health.max_value = maximum
    player_health.value = current


func _on_enemy_health_changed(current: int, maximum: int) -> void:
    enemy_health.max_value = maximum
    enemy_health.value = current


func _on_player_stamina_changed(current: float, maximum: float) -> void:
    player_stamina.max_value = maximum
    player_stamina.value = current


func _on_enemy_stamina_changed(current: float, maximum: float) -> void:
    enemy_stamina.max_value = maximum
    enemy_stamina.value = current


func _on_combo_changed(step: int) -> void:
    combo_label.text = "" if step <= 1 else "COMBO x%d" % step
