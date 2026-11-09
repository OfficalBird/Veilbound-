extends Node

const SAVE_PATH := "user://veilbound_save.cfg"

var total_match_wins: int = 0
var total_matches_played: int = 0


func _ready() -> void:
    load_save()


func record_match(player_won: bool) -> void:
    total_matches_played += 1
    if player_won:
        total_match_wins += 1
    save()


func save() -> void:
    var config := ConfigFile.new()
    config.set_value("profile", "total_match_wins", total_match_wins)
    config.set_value("profile", "total_matches_played", total_matches_played)
    config.save(SAVE_PATH)


func load_save() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return

    total_match_wins = int(config.get_value("profile", "total_match_wins", 0))
    total_matches_played = int(config.get_value("profile", "total_matches_played", 0))
