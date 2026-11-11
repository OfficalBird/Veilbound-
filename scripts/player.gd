extends "res://scripts/fighter_base.gd"

var input_prefix: String = ""

func _read_commands(_delta: float) -> Dictionary:
    return {
        "move":Input.get_axis(input_prefix + "move_left", input_prefix + "move_right"),
        "jump":Input.is_action_just_pressed(input_prefix + "jump"),
        "light":Input.is_action_just_pressed(input_prefix + "light_attack"),
        "heavy":Input.is_action_just_pressed(input_prefix + "heavy_attack"),
        "special":Input.is_action_just_pressed(input_prefix + "special_attack"),
        "burst":Input.is_action_just_pressed(input_prefix + "veil_break"),
        "block":Input.is_action_pressed(input_prefix + "block"),
        "dodge":Input.is_action_just_pressed(input_prefix + "dodge")
    }
