extends "res://scripts/fighter_base.gd"

func _read_commands(_delta: float) -> Dictionary:
    return {
        "move":Input.get_axis("move_left", "move_right"),
        "jump":Input.is_action_just_pressed("jump"),
        "light":Input.is_action_just_pressed("light_attack"),
        "heavy":Input.is_action_just_pressed("heavy_attack"),
        "special":Input.is_action_just_pressed("special_attack"),
        "burst":Input.is_action_just_pressed("veil_break"),
        "block":Input.is_action_pressed("block"),
        "dodge":Input.is_action_just_pressed("dodge")
    }
