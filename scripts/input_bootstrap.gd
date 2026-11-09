extends Node

# Centralized input setup keeps the prototype playable even when project.godot
# is copied between machines. Actions can later be rebound from a settings menu.

func _ready() -> void:
    _ensure_key_action("move_left", KEY_A)
    _ensure_key_action("move_right", KEY_D)
    _ensure_key_action("jump", KEY_W)
    _ensure_key_action("light_attack", KEY_J)
    _ensure_key_action("heavy_attack", KEY_K)
    _ensure_key_action("block", KEY_L)
    _ensure_key_action("dodge", KEY_SHIFT)
    _ensure_key_action("special_attack", KEY_I)


func _ensure_key_action(action_name: StringName, keycode) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    if InputMap.action_get_events(action_name).is_empty():
        var event := InputEventKey.new()
        event.physical_keycode = keycode
        InputMap.action_add_event(action_name, event)
