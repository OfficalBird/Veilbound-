extends Node

const SAVE_PATH: String = "user://veilbound_save.cfg"
var total_match_wins: int = 0
var total_matches_played: int = 0
var arcade_clears: int = 0
var best_combo: int = 0
var survival_best: int = 0
var settings: Dictionary = {"master":0.8,"music":0.45,"sfx":0.8,"shake":true,"flashes":true,"fullscreen":false,"difficulty":1}
var bindings: Dictionary = {}

func _ready() -> void:
    load_save()
    apply_settings()

func record_match(won: bool) -> void:
    total_matches_played += 1
    if won: total_match_wins += 1
    save()

func apply_settings() -> void:
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(settings["master"]))))
    AudioServer.set_bus_mute(0, float(settings["master"]) <= 0.0)
    if not OS.has_feature("web"):
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings["fullscreen"]) else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
    var config := ConfigFile.new()
    config.set_value("profile", "wins", total_match_wins)
    config.set_value("profile", "matches", total_matches_played)
    config.set_value("profile", "arcade_clears", arcade_clears)
    config.set_value("profile", "best_combo", best_combo)
    config.set_value("profile", "survival_best", survival_best)
    for key: String in settings: config.set_value("settings", key, settings[key])
    for key: String in bindings: config.set_value("bindings", key, bindings[key])
    config.save(SAVE_PATH)

func load_save() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK: return
    total_match_wins = maxi(0, int(config.get_value("profile", "wins", config.get_value("profile", "total_match_wins", 0))))
    total_matches_played = maxi(0, int(config.get_value("profile", "matches", config.get_value("profile", "total_matches_played", 0))))
    arcade_clears = maxi(0, int(config.get_value("profile", "arcade_clears", 0)))
    survival_best = maxi(0, int(config.get_value("profile", "survival_best", 0)))
    best_combo = maxi(0, int(config.get_value("profile", "best_combo", 0)))
    for key: String in settings:
        var value: Variant = config.get_value("settings", key, settings[key])
        if key in ["master", "music", "sfx"]: settings[key] = clampf(float(value), 0.0, 1.0)
        elif key == "difficulty": settings[key] = clampi(int(value), 0, 2)
        else: settings[key] = bool(value)
    if config.has_section("bindings"):
        for key: String in config.get_section_keys("bindings"):
            bindings[key] = int(config.get_value("bindings", key))
