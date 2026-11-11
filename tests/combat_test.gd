extends SceneTree

var checks: int = 0
var failures: int = 0
var game: Node2D
var save_snapshot: Dictionary

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, title: String) -> void:
    checks += 1
    if value: print("PASS  ",title)
    else:
        failures += 1
        push_error("FAIL  "+title)

func reset_pair() -> void:
    game.world.process_mode = Node.PROCESS_MODE_DISABLED
    game.hitstop = 0.0
    game.player.reset_fighter(Vector2(500,550))
    game.enemy.reset_fighter(Vector2(595,550))
    game.player.combat_enabled = true
    game.enemy.combat_enabled = true
    game.player.facing = 1
    game.enemy.facing = -1
    game.enemy.max_health = 100
    game.enemy.health = 100
    game.player.meter = 0
    game.enemy.meter = 0

func _run() -> void:
    await process_frame
    var save_manager: Node = root.get_node("SaveManager")
    save_snapshot = {"wins":save_manager.total_match_wins,"matches":save_manager.total_matches_played,"clears":save_manager.arcade_clears,"combo":save_manager.best_combo}
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    await process_frame
    check(game.state=="menu" and game.hud.menu_kind=="title","title screen loads")
    game._select_mode("training")
    game._start_match()
    check(not game.player.combat_enabled and not game.enemy.combat_enabled,"countdown locks both fighters")
    game._process(3.0)
    check(game.state=="fight" and game.player.combat_enabled,"countdown enables combat")
    check(game.enemy.training_behavior==0,"training starts with idle dummy")
    reset_pair()
    var light: Dictionary = load("res://scripts/moves.gd").attack("light",0)
    check(is_equal_approx(light.windup,0.08) and is_equal_approx(light.active,0.1) and is_equal_approx(light.cooldown,0.4),"original light timing retained")
    check(game.player._start_attack("light"),"light starts when ready")
    game.player._tick_attack(0.081)
    check(game.enemy.health==90,"light deals exactly ten damage")
    game.player._tick_attack(0.03)
    check(game.enemy.health==90,"one target is hit once during active window")
    check(not game.player._start_attack("light"),"cooldown and attack state prevent immediate repeats")
    reset_pair()
    game.enemy.position.x=900
    game.player._start_attack("light")
    game.player._tick_attack(0.081)
    check(game.enemy.health==100,"out-of-range active attack misses")
    game.enemy.position.x=595
    game.player._tick_attack(0.02)
    check(game.enemy.health==90,"entering later in active window registers a hit")
    reset_pair()
    game.enemy.blocking=true
    game.enemy.parry_remaining=0.1
    game.enemy.receive_attack(light,game.player)
    check(game.enemy.health==100 and game.player.hitstun_remaining>=0.6,"perfect parry prevents damage and staggers attacker")
    check(game.enemy.meter>=20,"parry builds Veil meter")
    reset_pair()
    game.enemy.blocking=true
    game.enemy.receive_attack(light,game.player)
    check(game.enemy.health==98 and game.enemy.stamina==90,"guard applies chip damage and stamina cost")
    reset_pair()
    game.enemy.blocking=true
    game.enemy.facing=1
    game.enemy.receive_attack(light,game.player)
    check(game.enemy.health==90,"guard cannot block attacks from behind")
    reset_pair()
    game.enemy.blocking=true
    game.enemy.stamina=1
    game.enemy.receive_attack(light,game.player)
    check(not game.enemy.blocking and game.enemy.hitstun_remaining>=0.75,"empty guard breaks")
    reset_pair()
    game.enemy.dodge_remaining=0.1
    check(not game.enemy.receive_attack(light,game.player) and game.enemy.health==100,"dodge grants temporary immunity")
    reset_pair()
    game.player.stamina=5
    check(not game.player._start_attack("heavy") and game.player.stamina==5,"insufficient stamina prevents heavy attack")
    check(not game.player._start_attack("burst"),"Veil break requires full meter")
    game.player.meter=100
    check(game.player._start_attack("burst") and game.player.meter==0,"Veil break consumes full meter")
    reset_pair()
    game.enemy.health=5
    game.enemy.receive_attack(light,game.player)
    check(game.enemy.is_defeated and game.enemy.health==0,"lethal damage defeats fighter")
    check(not game.enemy.receive_attack(light,game.player),"defeated fighter rejects further damage")
    game._reset_training()
    check(game.player.health==game.player.max_health and game.enemy.health==game.enemy.max_health and game.player.meter==100,"training reset restores fighters and meter")
    game.mode="duel"
    game.state="fight"
    game._end_round(1)
    check(game.player_score==1 and not game.player.combat_enabled,"round result increments score and locks combat")
    game._process(2.0)
    check(game.state=="countdown" and game.current_round==2,"round flow starts next round")
    game._process(3.0)
    game._end_round(1)
    game._process(2.0)
    check(game.state=="result" and game.hud.menu_kind=="result","best-of-three ends at two wins")
    check(save_manager.total_match_wins==int(save_snapshot.wins)+1,"completed duel records career result once")
    game._select_mode("arcade")
    game._start_match()
    check(game.enemy.max_health==90,"arcade begins with first rival")
    game._on_action("next",null)
    check(game.arcade_index==1 and game.enemy.max_health==110,"arcade advances to second rival")
    game._on_action("next",null)
    check(game.arcade_index==2 and game.enemy.max_health==130,"arcade advances to final rival")
    game.selected_hero=1
    game._start_match()
    check(game.player.fighter_id=="nyra" and game.player.move_speed>300,"second fighter has distinct movement")
    game._process(3.0)
    game._pause()
    check(paused and game.hud.menu_kind=="pause","pause menu pauses combat")
    game._open_auxiliary("options")
    check(game.hud.menu_kind=="options","options opens while paused")
    game._back()
    game._resume()
    check(not paused and game.hud.menu_kind=="","resume returns to combat")
    game._show_title()
    game._open_auxiliary("controls")
    check(game.hud.menu_kind=="controls","controls screen builds")
    game._back()
    game._open_auxiliary("credits")
    check(game.hud.menu_kind=="credits","credits screen builds")
    save_manager.total_match_wins=int(save_snapshot.wins)
    save_manager.total_matches_played=int(save_snapshot.matches)
    save_manager.arcade_clears=int(save_snapshot.clears)
    save_manager.best_combo=int(save_snapshot.combo)
    save_manager.save()
    game.queue_free()
    await process_frame
    print("COMBAT TESTS: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
