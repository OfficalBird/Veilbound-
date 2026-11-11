extends Node

const DEFAULTS: Dictionary = {"move_left":KEY_A,"move_right":KEY_D,"jump":KEY_W,"light_attack":KEY_J,"heavy_attack":KEY_K,"block":KEY_L,"dodge":KEY_SHIFT,"special_attack":KEY_I,"veil_break":KEY_U}
const TITLES: Dictionary = {"move_left":"Move left","move_right":"Move right","jump":"Jump","light_attack":"Light / combo","heavy_attack":"Heavy strike","block":"Guard / parry","dodge":"Dodge","special_attack":"Veil bolt","veil_break":"Veil break"}
const PAD: Dictionary = {"jump":JOY_BUTTON_A,"light_attack":JOY_BUTTON_X,"heavy_attack":JOY_BUTTON_Y,"dodge":JOY_BUTTON_B,"block":JOY_BUTTON_LEFT_SHOULDER,"special_attack":JOY_BUTTON_RIGHT_SHOULDER,"veil_break":JOY_BUTTON_RIGHT_STICK}

func _ready() -> void:
    for action: String in DEFAULTS:
        if not InputMap.has_action(action): InputMap.add_action(action, 0.2)
        rebind(action, int(SaveManager.bindings.get(action, DEFAULTS[action])), false)
    for pair: Array in [["move_left",KEY_LEFT],["move_right",KEY_RIGHT],["jump",KEY_UP],["jump",KEY_SPACE]]:
        var event := InputEventKey.new()
        event.physical_keycode = int(pair[1])
        InputMap.action_add_event(str(pair[0]), event)
    for action: String in PAD:
        var event := InputEventJoypadButton.new()
        event.button_index = int(PAD[action])
        InputMap.action_add_event(action, event)
    for pair: Array in [["move_left",-1.0],["move_right",1.0]]:
        var event := InputEventJoypadMotion.new()
        event.axis = JOY_AXIS_LEFT_X
        event.axis_value = float(pair[1])
        InputMap.action_add_event(str(pair[0]), event)
    for pair: Array in [["move_left",JOY_BUTTON_DPAD_LEFT],["move_right",JOY_BUTTON_DPAD_RIGHT],["jump",JOY_BUTTON_DPAD_UP]]:
        var event := InputEventJoypadButton.new()
        event.button_index = int(pair[1])
        InputMap.action_add_event(str(pair[0]), event)

func rebind(action: String, keycode: int, persist: bool = true) -> void:
    if not DEFAULTS.has(action): return
    for event: InputEvent in InputMap.action_get_events(action):
        if event is InputEventKey: InputMap.action_erase_event(action, event)
    var key := InputEventKey.new()
    key.physical_keycode = keycode
    InputMap.action_add_event(action, key)
    SaveManager.bindings[action] = keycode
    if persist: SaveManager.save()

func key_text(action: String) -> String:
    return OS.get_keycode_string(int(SaveManager.bindings.get(action, DEFAULTS.get(action, 0))))
