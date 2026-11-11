extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const StageScript = preload("res://scripts/stage.gd")
const HudScript = preload("res://scripts/hud.gd")
const ProjectileScript = preload("res://scripts/veil_projectile.gd")
const PLAYER_SPAWN := Vector2(320,550)
const ENEMY_SPAWN := Vector2(832,550)
const RIVALS: Array[Dictionary] = [
    {"name":"THE WATCHER","fighter":"nyra","health":90,"damage":0.85,"speed":215.0,"color":Color(0.9,0.96,1.0),"line":"The first seal keeps the timid outside."},
    {"name":"SABLE, EXILED BLADE","fighter":"kael","health":110,"damage":1.0,"speed":245.0,"color":Color(1.0,0.75,0.8),"line":"Every blade casts a shadow. Face yours."},
    {"name":"VESPER, THE HOLLOW CROWN","fighter":"nyra","health":130,"damage":1.14,"speed":270.0,"color":Color(0.86,0.75,1.0),"line":"Break the final seal. Bring back the dawn."}
]

var world: Node2D
var stage: Node2D
var hud: CanvasLayer
var flash: ColorRect
var player: FighterBase
var enemy: FighterBase
var mode: String = "duel"
var state: String = "menu"
var selected_hero: int = 0
var selected_stage: int = 0
var difficulty: int = 1
var arcade_index: int = 0
var current_round: int = 1
var player_score: int = 0
var enemy_score: int = 0
var time_remaining: float = 60.0
var state_timer: float = 0.0
var hitstop: float = 0.0
var shake: float = 0.0
var flash_life: float = 0.0
var combo_hits: int = 0
var combo_damage: int = 0
var combo_expire: float = 0.0
var match_best_combo: int = 0
var match_damage: int = 0
var training_behavior: int = 0
var training_reset: float = -1.0
var back_screen: String = "title"
var remap_action: String = ""
var fight_announced: bool = false
var round_winner: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    difficulty = int(SaveManager.settings["difficulty"])
    stage = StageScript.new()
    stage.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(stage)
    world = Node2D.new()
    world.name = "Arena"
    world.process_mode = Node.PROCESS_MODE_PAUSABLE
    add_child(world)
    _build_floor()
    hud = HudScript.new()
    add_child(hud)
    hud.action_requested.connect(_on_action)
    var fx_layer := CanvasLayer.new()
    fx_layer.layer = 3
    add_child(fx_layer)
    flash = ColorRect.new()
    flash.size = Vector2(1152,648)
    flash.color = Color(0.8,0.95,1.0,0.0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_layer.add_child(flash)
    _show_title()

func _build_floor() -> void:
    var floor_body := StaticBody2D.new()
    floor_body.name = "Floor"
    floor_body.collision_layer = 4
    floor_body.collision_mask = 3
    floor_body.position = Vector2(576,610)
    var shape := RectangleShape2D.new()
    shape.size = Vector2(2500,120)
    var collision := CollisionShape2D.new()
    collision.shape = shape
    floor_body.add_child(collision)
    world.add_child(floor_body)

func _clear_fighters() -> void:
    for child: Node in world.get_children():
        if child.name != "Floor":
            world.remove_child(child)
            child.queue_free()
    player = null
    enemy = null

func _spawn_fighters() -> void:
    _clear_fighters()
    var rival: Dictionary = RIVALS[arcade_index] if mode == "arcade" else RIVALS[1]
    player = PlayerScript.new()
    player.name = "Player"
    player.fighter_id = "kael" if selected_hero == 0 else "nyra"
    player.display_name = "KAEL / THE VEILWALKER" if selected_hero == 0 else "NYRA / THE DUSK BLADE"
    player.accent = Color("79ded7") if selected_hero == 0 else Color("c1a4e9")
    player.collision_layer = 1
    player.collision_mask = 6
    player.position = PLAYER_SPAWN
    world.add_child(player)
    enemy = EnemyScript.new()
    enemy.name = "Enemy"
    enemy.fighter_id = str(rival["fighter"])
    enemy.display_name = str(rival["name"])
    enemy.max_health = int(rival["health"]) if mode == "arcade" else 100
    enemy.damage_multiplier = float(rival["damage"]) * [0.75,1.0,1.13][difficulty]
    enemy.move_speed = float(rival["speed"]) * [0.85,1.0,1.08][difficulty]
    enemy.costume_tint = rival["color"]
    enemy.accent = Color("d0a6ed")
    enemy.difficulty = difficulty
    enemy.collision_layer = 2
    enemy.collision_mask = 5
    enemy.position = ENEMY_SPAWN
    enemy.facing = -1
    enemy.training_behavior = training_behavior if mode == "training" else 2
    world.add_child(enemy)
    player.opponent = enemy
    enemy.opponent = player
    player.defeated.connect(_on_defeated)
    enemy.defeated.connect(_on_defeated)
    player.combat_event.connect(_on_combat_event)
    enemy.combat_event.connect(_on_combat_event)
    hud.bind_fighters(player,enemy)
    hud.training_label.visible = mode == "training"
    if mode == "training": hud.set_training(training_behavior)

func _show_title() -> void:
    get_tree().paused = false
    world.process_mode = Node.PROCESS_MODE_PAUSABLE
    hitstop = 0.0
    state = "menu"
    remap_action = ""
    _clear_fighters()
    stage.set_theme(0)
    hud.show_title()

func _select_mode(new_mode: String) -> void:
    mode = new_mode
    arcade_index = 0
    state = "selection"
    hud.show_select(selected_hero,mode,difficulty,selected_stage)

func _start_match() -> void:
    get_tree().paused = false
    world.process_mode = Node.PROCESS_MODE_PAUSABLE
    hitstop = 0.0
    player_score = 0
    enemy_score = 0
    current_round = 1
    combo_hits = 0
    combo_damage = 0
    combo_expire = 0
    match_best_combo = 0
    match_damage = 0
    _spawn_fighters()
    stage.set_theme(selected_stage)
    hud.close_menu()
    _begin_round()

func _begin_round() -> void:
    for child: Node in world.get_children():
        if child is ProjectileScript: child.queue_free()
    player.reset_fighter(PLAYER_SPAWN)
    enemy.reset_fighter(ENEMY_SPAWN)
    player.combat_enabled = false
    enemy.combat_enabled = false
    player.facing = 1
    enemy.facing = -1
    time_remaining = 60.0
    hud.set_timer(time_remaining,mode=="training")
    hud.set_score(player_score,enemy_score)
    state = "countdown"
    state_timer = 2.1
    fight_announced = false
    training_reset = -1.0
    if mode == "training":
        player.meter = 100
        enemy.meter = 100
        state_timer = 0.8
        hud.set_message("TRAINING", "Explore. Experiment. Reset freely.")
    else:
        var rival: Dictionary = RIVALS[arcade_index] if mode=="arcade" else RIVALS[1]
        hud.set_message("ROUND %d" % current_round,str(rival["line"]))
    AudioManager.play("round")

func _process(delta: float) -> void:
    if get_tree().paused: return
    if hitstop > 0.0:
        hitstop -= delta
        if hitstop <= 0.0: world.process_mode = Node.PROCESS_MODE_PAUSABLE
    shake = maxf(0.0,shake-delta*25.0)
    var offset := Vector2.ZERO
    if shake > 0.0 and bool(SaveManager.settings["shake"]): offset = Vector2(randf_range(-shake,shake),randf_range(-shake,shake)*0.5)
    world.position = offset
    stage.position = offset*0.45
    flash_life = maxf(0.0,flash_life-delta)
    flash.color.a = flash_life*1.6 if bool(SaveManager.settings["flashes"]) else 0.0
    combo_expire = maxf(0.0,combo_expire-delta)
    if state == "countdown":
        state_timer -= delta
        if state_timer < 0.6 and not fight_announced and mode != "training":
            hud.set_message("FIGHT")
            fight_announced = true
        if state_timer <= 0.0:
            state = "fight"
            player.combat_enabled = true
            enemy.combat_enabled = true
            hud.set_message("")
    elif state == "fight":
        if mode != "training":
            time_remaining = maxf(0.0,time_remaining-delta)
            hud.set_timer(time_remaining)
            if time_remaining <= 0.0: _resolve_timeout()
        else:
            if player.is_defeated or enemy.is_defeated:
                if training_reset < 0.0: training_reset = 0.7
                training_reset -= delta
                if training_reset <= 0.0: _reset_training()
    elif state == "round_end":
        state_timer -= delta
        if state_timer <= 0.0:
            if player_score >= 2 or enemy_score >= 2:
                _finish_match()
            else:
                current_round += 1
                _begin_round()

func _on_defeated(fighter: FighterBase) -> void:
    if state != "fight" or mode=="training": return
    _end_round(1 if fighter==enemy else -1)

func _resolve_timeout() -> void:
    var winner: int = 0
    if player.get_health_ratio() > enemy.get_health_ratio(): winner = 1
    elif enemy.get_health_ratio() > player.get_health_ratio(): winner = -1
    _end_round(winner,true)

func _end_round(winner: int, timeout: bool = false) -> void:
    if state != "fight": return
    state = "round_end"
    state_timer = 1.8
    round_winner = winner
    player.combat_enabled = false
    enemy.combat_enabled = false
    player.cancel_attack()
    enemy.cancel_attack()
    for child: Node in world.get_children():
        if child is ProjectileScript: child.queue_free()
    if winner > 0: player_score += 1
    elif winner < 0: enemy_score += 1
    hud.set_score(player_score,enemy_score)
    hud.set_message("TIME" if timeout else "K.O.","ROUND WON" if winner>0 else "ROUND LOST" if winner<0 else "DRAW / FIGHT AGAIN")
    AudioManager.play("victory" if winner>0 else "defeat")

func _finish_match() -> void:
    state = "result"
    var won: bool = player_score > enemy_score
    var cleared: bool = won and mode=="arcade" and arcade_index==2
    SaveManager.record_match(won)
    SaveManager.best_combo = maxi(SaveManager.best_combo,match_best_combo)
    if cleared: SaveManager.arcade_clears += 1
    SaveManager.save()
    var summary: String = "Best combo: %d hits   /   Damage dealt: %d" % [match_best_combo,match_damage]
    if cleared: summary = "Three seals shattered. Dawn returns to Moonfall.\n"+summary
    elif mode=="arcade": summary = "SEAL %d OF 3\n" % (arcade_index+1)+summary
    hud.show_result(won,mode=="arcade",cleared,"%d  —  %d" % [player_score,enemy_score],summary)

func _reset_training() -> void:
    for child: Node in world.get_children():
        if child is ProjectileScript: child.queue_free()
    player.reset_fighter(PLAYER_SPAWN)
    enemy.reset_fighter(ENEMY_SPAWN)
    player.meter = 100
    enemy.meter = 100
    player.combat_enabled = true
    enemy.combat_enabled = true
    training_reset = -1.0
    combo_expire = 0.0
    hud.announce("TRAINING RESET")

func _on_combat_event(kind: String, source: Node, target: Node, amount: int) -> void:
    var source_fighter: FighterBase = source as FighterBase
    var target_fighter: FighterBase = target as FighterBase
    if kind == "projectile" and source_fighter != null:
        var projectile := ProjectileScript.new()
        projectile.owner_fighter = source_fighter
        projectile.target = source_fighter.opponent
        projectile.direction = source_fighter.facing
        projectile.position = source_fighter.position + Vector2(source_fighter.facing*65,-72)
        projectile.tint = source_fighter.accent
        projectile.attack_data = source_fighter.current_attack.duplicate()
        world.add_child(projectile)
    if kind in ["hit","block","parry","guard_break"]:
        var point: Vector2 = target_fighter.position + Vector2(0,-72) if target_fighter != null else source_fighter.position+Vector2(0,-72)
        var color: Color = Color("f6deaa") if kind=="parry" else Color("b5eefa") if kind=="block" else source_fighter.accent if source_fighter != null else Color.WHITE
        stage.add_impact(point,color,kind,amount)
        hitstop = 0.035 if kind=="block" else 0.065 if kind=="hit" else 0.1
        world.process_mode = Node.PROCESS_MODE_DISABLED
        shake = maxf(shake,2.0 if kind=="block" else 5.0 if kind=="hit" else 9.0)
        if kind in ["parry","guard_break"]:
            hud.announce("PERFECT PARRY" if kind=="parry" else "GUARD BROKEN")
            flash_life = 0.1
        if source==player and kind in ["hit","guard_break"]:
            if combo_expire <= 0.0:
                combo_hits = 0
                combo_damage = 0
            combo_hits += 1
            combo_damage += amount
            combo_expire = 0.95
            match_damage += amount
            match_best_combo = maxi(match_best_combo,combo_hits)
            hud.show_combo(combo_hits,combo_damage)
    elif kind in ["land","jump","dodge"] and source_fighter != null:
        stage.add_impact(source_fighter.position,source_fighter.accent,kind)
    elif kind=="burst":
        hud.announce("VEIL BREAK")
        flash_life = 0.14
        shake = 8.0
    AudioManager.play(kind)

func _pause() -> void:
    if state not in ["fight","countdown","round_end"]: return
    get_tree().paused = true
    hud.show_pause()

func _resume() -> void:
    get_tree().paused = false
    hud.close_menu()
    if state=="countdown": hud.set_message("READY", "The duel resumes.")

func _open_auxiliary(screen: String) -> void:
    back_screen = "pause" if get_tree().paused else "select" if state=="selection" else "title"
    match screen:
        "options": hud.show_options()
        "controls": hud.show_controls()
        "credits": hud.show_credits()

func _back() -> void:
    remap_action = ""
    if back_screen=="pause": hud.show_pause()
    elif back_screen=="select": hud.show_select(selected_hero,mode,difficulty,selected_stage)
    else: hud.show_title()

func _on_action(action: String, value: Variant) -> void:
    match action:
        "title": _show_title()
        "mode": _select_mode(str(value))
        "hero":
            selected_hero = int(value)
            hud.show_select(selected_hero,mode,difficulty,selected_stage)
        "difficulty":
            difficulty = int(value)
            SaveManager.settings["difficulty"] = difficulty
            SaveManager.save()
        "stage":
            selected_stage = int(value)
            stage.set_theme(selected_stage)
        "start": _start_match()
        "restart": _start_match()
        "next":
            arcade_index = mini(2,arcade_index+1)
            _start_match()
        "resume": _resume()
        "options","controls","credits": _open_auxiliary(action)
        "back": _back()
        "quit": get_tree().quit()
        "setting":
            for key: String in value: SaveManager.settings[key] = value[key]
            SaveManager.apply_settings()
            AudioManager.apply_volumes()
            SaveManager.save()
        "rebind":
            remap_action = str(value)
            hud.show_rebind(remap_action)

func _input(event: InputEvent) -> void:
    if remap_action != "" and event is InputEventKey and event.pressed and not event.echo:
        var code: int = event.physical_keycode
        if code==KEY_ESCAPE:
            remap_action = ""
            hud.show_options()
        elif code not in [KEY_R,KEY_T,KEY_F3,KEY_F11,KEY_ENTER,KEY_KP_ENTER] and code != 0:
            var duplicate_action: String = ""
            for action: String in InputBootstrap.DEFAULTS:
                if action != remap_action and int(SaveManager.bindings.get(action,InputBootstrap.DEFAULTS[action]))==code:
                    duplicate_action = action
                    break
            if duplicate_action != "":
                var old_code: int = int(SaveManager.bindings.get(remap_action,InputBootstrap.DEFAULTS[remap_action]))
                InputBootstrap.rebind(duplicate_action,old_code)
            InputBootstrap.rebind(remap_action,code)
            remap_action = ""
            hud.show_options()
        get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
    var escape: bool = event.is_action_pressed("ui_cancel")
    if escape:
        if hud.menu_kind in ["options","controls","credits"]: _back()
        elif get_tree().paused: _resume()
        elif state in ["fight","countdown","round_end"]: _pause()
        elif state in ["selection","result"]: _show_title()
        get_viewport().set_input_as_handled()
        return
    if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START:
        if get_tree().paused: _resume()
        else: _pause()
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.physical_keycode:
        KEY_F11:
            SaveManager.settings["fullscreen"] = not bool(SaveManager.settings["fullscreen"])
            SaveManager.apply_settings()
            SaveManager.save()
        KEY_R:
            if state in ["fight","countdown","round_end","result"] and not get_tree().paused:
                if mode=="training" and state=="fight": _reset_training()
                else: _start_match()
        KEY_T:
            if mode=="training" and state=="fight" and not get_tree().paused:
                training_behavior = (training_behavior+1)%3
                enemy.training_behavior = training_behavior
                enemy.blocking = false
                enemy.guard_was_held = false
                hud.set_training(training_behavior)
        KEY_F3:
            if is_instance_valid(player):
                player.debug_hitboxes = not player.debug_hitboxes
                enemy.debug_hitboxes = player.debug_hitboxes
                hud.debug_label.visible = player.debug_hitboxes
