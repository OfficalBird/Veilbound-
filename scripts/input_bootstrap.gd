extends Node

const DEFAULTS: Dictionary = {"move_left":KEY_A,"move_right":KEY_D,"jump":KEY_W,"light_attack":KEY_J,"heavy_attack":KEY_K,"block":KEY_L,"dodge":KEY_SHIFT,"special_attack":KEY_I,"veil_break":KEY_U}
const TITLES: Dictionary = {"move_left":"Move left","move_right":"Move right","jump":"Jump","light_attack":"Light / combo","heavy_attack":"Heavy strike","block":"Guard / parry","dodge":"Dodge","special_attack":"Veil bolt","veil_break":"Veil break"}
const PAD: Dictionary = {"jump":JOY_BUTTON_A,"light_attack":JOY_BUTTON_X,"heavy_attack":JOY_BUTTON_Y,"dodge":JOY_BUTTON_B,"block":JOY_BUTTON_LEFT_SHOULDER,"special_attack":JOY_BUTTON_RIGHT_SHOULDER,"veil_break":JOY_BUTTON_RIGHT_STICK}

const SECOND_KEYS: Dictionary = {"move_left":KEY_LEFT,"move_right":KEY_RIGHT,"jump":KEY_UP,"light_attack":KEY_COMMA,"heavy_attack":KEY_PERIOD,"block":KEY_SLASH,"dodge":KEY_ENTER,"special_attack":KEY_SEMICOLON,"veil_break":KEY_APOSTROPHE}

func _ready() -> void:
    for action: String in SECOND_KEYS:
        InputMap.add_action("p2_" + action, 0.2)
        var key := InputEventKey.new()
        if action in ["move_left", "move_right", "jump", "dodge"]:
            key.keycode = int(SECOND_KEYS[action])
        else:
            key.physical_keycode = int(SECOND_KEYS[action])
        InputMap.action_add_event("p2_" + action, key)
        InputMap.add_action("p1_" + action, 0.2)
        var first := InputEventKey.new()
        first.physical_keycode = int(SaveManager.bindings.get(action, DEFAULTS[action]))
        InputMap.action_add_event("p1_" + action, first)
    for prefix: String in ["p1_", "p2_"]:
        var device_id: int = 0 if prefix == "p1_" else 1
        for action: String in PAD:
            var pad_event := InputEventJoypadButton.new()
            pad_event.device = device_id
            pad_event.button_index = int(PAD[action])
            InputMap.action_add_event(prefix + action, pad_event)
        for pair: Array in [["move_left", -1.0], ["move_right", 1.0]]:
            var stick := InputEventJoypadMotion.new()
            stick.device = device_id
            stick.axis = JOY_AXIS_LEFT_X
            stick.axis_value = float(pair[1])
            InputMap.action_add_event(prefix + str(pair[0]), stick)
        for pair: Array in [["move_left", JOY_BUTTON_DPAD_LEFT], ["move_right", JOY_BUTTON_DPAD_RIGHT], ["jump", JOY_BUTTON_DPAD_UP]]:
            var dpad := InputEventJoypadButton.new()
            dpad.device = device_id
            dpad.button_index = int(pair[1])
            InputMap.action_add_event(prefix + str(pair[0]), dpad)
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
    if InputMap.has_action("p1_" + action):
        for event: InputEvent in InputMap.action_get_events("p1_" + action):
            if event is InputEventKey: InputMap.action_erase_event("p1_" + action, event)
        var local_key := InputEventKey.new()
        local_key.physical_keycode = keycode
        InputMap.action_add_event("p1_" + action, local_key)
    if persist: SaveManager.save()

func key_text(action: String) -> String:
    return OS.get_keycode_string(int(SaveManager.bindings.get(action, DEFAULTS.get(action, 0))))
