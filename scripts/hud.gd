extends CanvasLayer

signal action_requested(action: String, value: Variant)

const FONT = preload("res://art/fonts/interface.ttf")
const DISPLAY = preload("res://art/fonts/display.ttf")
const KAEL = preload("res://art/fighters/kael.png")
const NYRA = preload("res://art/fighters/nyra.png")
const INK := Color("111827")
const TEXT := Color("e9ebf2")
const MUTED := Color("9aadc0")
const GOLD := Color("e3c799")
const TEAL := Color("79ded7")
const VIOLET := Color("c1a4e9")

var root: Control
var menu: Control
var combat: Control
var overlay: Control
var player: FighterBase
var enemy: FighterBase
var player_health: ProgressBar
var enemy_health: ProgressBar
var player_lag: ProgressBar
var enemy_lag: ProgressBar
var player_stamina: ProgressBar
var enemy_stamina: ProgressBar
var player_meter: ProgressBar
var enemy_meter: ProgressBar
var timer_label: Label
var score_label: Label
var message_label: Label
var subtitle_label: Label
var combo_label: Label
var toast_label: Label
var training_label: Label
var debug_label: Label
var hint_label: Label
var toast_time: float = 0.0
var combo_time: float = 0.0
var menu_kind: String = ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)
    combat = Control.new()
    combat.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(combat)
    menu = Control.new()
    menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(menu)
    overlay = Control.new()
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(overlay)
    _build_combat()

func box(rect: Rect2, color: Color, parent: Control, border: Color = Color.TRANSPARENT, thickness: int = 1) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(thickness)
    style.corner_radius_top_left = 5
    style.corner_radius_top_right = 5
    style.corner_radius_bottom_left = 5
    style.corner_radius_bottom_right = 5
    panel.add_theme_stylebox_override("panel",style)
    parent.add_child(panel)
    return panel

func text(value: String, rect: Rect2, font_size: int, color: Color = TEXT, parent: Control = null, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var label := Label.new()
    label.text = value
    label.position = rect.position
    label.size = rect.size
    label.horizontal_alignment = align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_override("font", DISPLAY if font_size >= 22 else FONT)
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    label.add_theme_constant_override("outline_size",2)
    label.add_theme_color_override("font_outline_color",Color(0.02,0.03,0.06,0.55))
    (parent if parent != null else menu).add_child(label)
    return label

func button(value: String, rect: Rect2, id: String, parent: Control = null, primary: bool = false, payload: Variant = null) -> Button:
    var control := Button.new()
    control.text = value
    control.position = rect.position
    control.size = rect.size
    control.add_theme_font_override("font",DISPLAY)
    control.add_theme_font_size_override("font_size",16)
    control.add_theme_color_override("font_color",INK if primary else TEXT)
    control.add_theme_color_override("font_hover_color",INK if primary else Color.WHITE)
    control.add_theme_color_override("font_focus_color",INK if primary else Color.WHITE)
    for state: String in ["normal","hover","pressed","focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = GOLD if primary else Color(0.065,0.095,0.15,0.95)
        style.border_color = GOLD if primary else Color("3a5069")
        if state == "hover" or state == "focus":
            style.bg_color = Color("f1d9af") if primary else Color("243b52")
            style.border_color = GOLD
        if state == "pressed": style.bg_color = Color("93866c") if primary else Color("364f64")
        style.set_border_width_all(1 if state != "focus" else 2)
        style.set_corner_radius_all(4)
        control.add_theme_stylebox_override(state,style)
    (parent if parent != null else menu).add_child(control)
    control.pressed.connect(func() -> void: AudioManager.play("ui"); action_requested.emit(id,payload))
    return control

func portrait(texture: Texture2D, rect: Rect2, parent: Control, tint: Color = Color.WHITE) -> void:
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    atlas.region = Rect2(0,0,texture.get_width()/4.0,texture.get_height()/2.0)
    var image := Sprite2D.new()
    image.texture = atlas
    image.position = rect.position + rect.size * 0.5
    var ratio: float = minf(rect.size.x / atlas.get_width(), rect.size.y / atlas.get_height())
    image.scale = Vector2.ONE * ratio
    image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    image.modulate = tint
    parent.add_child(image)

func _clear_menu() -> void:
    for child: Node in menu.get_children():
        menu.remove_child(child)
        child.queue_free()
    message_label.text = ""
    subtitle_label.text = ""
    menu.show()

func close_menu() -> void:
    _clear_menu()
    menu.hide()
    menu_kind = ""

func show_title() -> void:
    _clear_menu()
    menu_kind = "title"
    combat.hide()
    box(Rect2(0,0,1152,648),Color(0.015,0.025,0.06,0.63),menu)
    box(Rect2(62,65,3,74),GOLD,menu)
    text("THE SHATTERED VEIL",Rect2(88,61,700,27),14,GOLD)
    text("VEILBOUND",Rect2(83,88,750,83),68,TEXT)
    text("Steel remembers. Shadows endure.",Rect2(88,182,590,30),18,MUTED)
    portrait(KAEL,Rect2(640,130,400,440),menu,Color(0.8,0.94,1.0))
    var first: Button = button("ARCADE  /  THE THREE SEALS",Rect2(88,254,398,49),"mode",null,true,"arcade")
    button("QUICK DUEL",Rect2(88,315,192,43),"mode",null,false,"duel")
    button("TRAINING",Rect2(294,315,192,43),"mode",null,false,"training")
    button("LOCAL VERSUS",Rect2(88,371,192,43),"mode",null,false,"versus")
    button("SURVIVAL",Rect2(294,371,192,43),"mode",null,false,"survival")
    button("HOW TO PLAY",Rect2(88,427,192,40),"controls")
    button("OPTIONS",Rect2(294,427,192,40),"options")
    button("CREDITS",Rect2(88,478,192,30),"credits")
    if not OS.has_feature("web"): button("QUIT",Rect2(294,478,192,30),"quit")
    var stats: String = "%d WINS    /    %d DUELS    /    %d ARCADE CLEARS" % [SaveManager.total_match_wins,SaveManager.total_matches_played,SaveManager.arcade_clears]
    text(stats,Rect2(88,528,620,25),12,GOLD)
    text("A / D  MOVE     W  JUMP     J / K  STRIKE     L  GUARD",Rect2(88,573,850,24),12,MUTED)
    text("v%s  ·  SHERWIN DHALIWAL" % ProjectSettings.get_setting("application/config/version"),Rect2(88,606,700,20),11,Color("6c839c"))
    first.grab_focus()

func show_select(hero: int, mode: String, difficulty: int, stage_index: int, second_hero: int = 1) -> void:
    _clear_menu()
    menu_kind = "select"
    combat.hide()
    box(Rect2(0,0,1152,648),Color(0.02,0.03,0.07,0.84),menu)
    text("CHOOSE YOUR FIGHTER",Rect2(80,40,990,48),32,GOLD)
    text("%s  ·  MOONFALL SANCTUARY" % mode.to_upper(),Rect2(82,92,980,24),12,MUTED)
    for i: int in range(2):
        var x: float = 82.0+i*350.0
        box(Rect2(x,143,325,320),Color("111e30"),menu,GOLD if hero==i else Color("35475e"),2 if hero==i else 1)
        portrait(KAEL if i==0 else NYRA,Rect2(x+65,157,195,207),menu)
        text("KAEL" if i==0 else "NYRA",Rect2(x+20,367,285,38),27,TEAL if i==0 else VIOLET,null,HORIZONTAL_ALIGNMENT_CENTER)
        text("THE VEILWALKER" if i==0 else "THE DUSK BLADE",Rect2(x+20,405,285,20),11,MUTED,null,HORIZONTAL_ALIGNMENT_CENTER)
        button("SELECTED" if hero==i else "SELECT",Rect2(x+45,435,235,35),"hero",null,hero==i,i)
    text("KAEL  /  BALANCED",Rect2(824,163,270,28),16,TEAL)
    text("Measured strikes. Reliable damage.\nA versatile first choice.",Rect2(824,204,268,65),14,MUTED)
    text("NYRA  /  AGILE",Rect2(824,302,270,28),16,VIOLET)
    text("Faster movement and recovery.\nLighter hits reward pressure.",Rect2(824,343,268,65),14,MUTED)
    if mode == "versus":
        for child: Node in menu.get_children():
            if child is Label and child.position.x == 824: child.hide()
        text("PLAYER 2",Rect2(824,163,270,28),18,VIOLET)
        button("KAEL" + ("  ✓" if second_hero == 0 else ""),Rect2(824,220,248,44),"hero2",null,second_hero == 0,0)
        button("NYRA" + ("  ✓" if second_hero == 1 else ""),Rect2(824,278,248,44),"hero2",null,second_hero == 1,1)
        text("P1: A / D / W + J K L
P2: arrows + , . /
Enter dodge · ; bolt · ' break
Or two connected gamepads.",Rect2(824,347,270,120),13,MUTED)
    text("DIFFICULTY",Rect2(82,493,180,25),11,MUTED)
    var diff := OptionButton.new()
    diff.position = Vector2(82,524)
    diff.size = Vector2(240,38)
    for item: String in ["APPRENTICE","DUELIST","MASTER"]: diff.add_item(item)
    diff.select(difficulty)
    diff.disabled = mode == "versus"
    menu.add_child(diff)
    diff.item_selected.connect(func(index: int) -> void: action_requested.emit("difficulty",index))
    text("ARENA",Rect2(350,493,220,25),11,MUTED)
    var stages := OptionButton.new()
    stages.position = Vector2(350,524)
    stages.size = Vector2(240,38)
    for item: String in ["MOONFALL","EMBER DAWN","ECLIPSE CITADEL"]: stages.add_item(item)
    stages.select(stage_index)
    menu.add_child(stages)
    stages.item_selected.connect(func(index: int) -> void: action_requested.emit("stage",index))
    button("BACK",Rect2(82,592,180,35),"title")
    var begin: Button = button("ENTER THE VEIL  →",Rect2(767,514,305,50),"start",null,true)
    begin.grab_focus()

func show_pause() -> void:
    _clear_menu()
    menu_kind = "pause"
    box(Rect2(0,0,1152,648),Color(0.015,0.025,0.05,0.76),menu)
    box(Rect2(365,85,422,480),Color("111e30"),menu,Color("3c516a"))
    text("PAUSED",Rect2(395,108,362,60),36,GOLD,null,HORIZONTAL_ALIGNMENT_CENTER)
    var resume: Button = button("RESUME",Rect2(407,200,338,46),"resume",null,true)
    button("HOW TO PLAY",Rect2(407,258,338,42),"controls")
    button("OPTIONS",Rect2(407,312,338,42),"options")
    button("RESTART DUEL",Rect2(407,366,338,42),"restart")
    button("RETURN TO TITLE",Rect2(407,420,338,42),"title")
    text("ESC  /  RESUME",Rect2(407,494,338,24),12,MUTED,null,HORIZONTAL_ALIGNMENT_CENTER)
    resume.grab_focus()

func show_options() -> void:
    _clear_menu()
    menu_kind = "options"
    box(Rect2(0,0,1152,648),Color(0.02,0.03,0.07,0.94),menu)
    text("OPTIONS",Rect2(70,35,950,50),34,GOLD)
    text("AUDIO & DISPLAY",Rect2(72,109,480,30),14,TEAL)
    var row: int = 0
    for key: String in ["master","music","sfx"]:
        text({"master":"Master volume","music":"Music","sfx":"Effects"}[key],Rect2(72,158+row*64,190,30),15,TEXT)
        var slider := HSlider.new()
        slider.position = Vector2(285,163+row*64)
        slider.size = Vector2(225,24)
        slider.min_value = 0
        slider.max_value = 100
        slider.step = 1
        slider.value = float(SaveManager.settings[key])*100.0
        menu.add_child(slider)
        slider.value_changed.connect(func(value: float) -> void: action_requested.emit("setting",{key:value/100.0}))
        row += 1
    row = 0
    for key: String in ["shake","flashes","fullscreen"]:
        var check := CheckButton.new()
        check.text = {"shake":"Screen shake","flashes":"Impact flashes","fullscreen":"Fullscreen"}[key]
        check.position = Vector2(70,366+row*43)
        check.size = Vector2(450,35)
        check.button_pressed = bool(SaveManager.settings[key])
        check.add_theme_font_override("font",FONT)
        check.add_theme_font_size_override("font_size",15)
        menu.add_child(check)
        check.toggled.connect(func(value: bool) -> void: action_requested.emit("setting",{key:value}))
        row += 1
    text("KEYBOARD BINDINGS",Rect2(605,109,480,30),14,TEAL)
    var actions: Array[String] = ["move_left","move_right","jump","light_attack","heavy_attack","block","dodge","special_attack","veil_break"]
    for i: int in range(actions.size()):
        var id: String = actions[i]
        text(str(InputBootstrap.TITLES[id]),Rect2(605,155+i*36,260,31),14,TEXT)
        button(InputBootstrap.key_text(id),Rect2(885,155+i*36,180,29),"rebind",null,false,id)
    text("Gamepad: stick / D-pad · A jump · X light · Y heavy\nB dodge · LB guard · RB bolt · right stick click break",Rect2(605,500,500,52),12,MUTED)
    var back: Button = button("BACK",Rect2(72,576,210,40),"back",null,true)
    back.grab_focus()

func show_controls() -> void:
    _clear_menu()
    menu_kind = "controls"
    box(Rect2(0,0,1152,648),Color(0.02,0.03,0.07,0.94),menu)
    text("THE WAY OF THE BLADE",Rect2(72,35,1000,55),34,GOLD)
    text("BASIC MOVEMENT",Rect2(74,119,470,26),14,TEAL)
    text("Move with %s / %s. Jump with %s.\nKeep your opponent in front of you." % [InputBootstrap.key_text("move_left"),InputBootstrap.key_text("move_right"),InputBootstrap.key_text("jump")],Rect2(74,156,480,70),16,TEXT)
    text("PRESSURE & PUNISH",Rect2(74,257,470,27),14,TEAL)
    text("%s  Light attack — press again to chain up to 3 cuts.\n%s  Heavy strike — slower, powerful, costs stamina.\n%s  Veil bolt — ranged pressure, costs stamina." % [InputBootstrap.key_text("light_attack"),InputBootstrap.key_text("heavy_attack"),InputBootstrap.key_text("special_attack")],Rect2(74,294,490,114),15,TEXT)
    text("DEFENSE IS A WEAPON",Rect2(632,119,470,26),14,VIOLET)
    text("Hold %s to guard attacks from the front.\nGuard just before impact to parry and stagger.\n%s dodges in your movement direction, using stamina.\nAn empty guard breaks under pressure." % [InputBootstrap.key_text("block"),InputBootstrap.key_text("dodge")],Rect2(632,156,463,136),15,TEXT)
    text("BREAK THE VEIL",Rect2(632,326,470,26),14,VIOLET)
    text("Dealing and taking damage builds your Veil meter.\nAt 100%%, press %s for a devastating close-range strike.\nBest of three rounds. Win on health when time expires." % InputBootstrap.key_text("veil_break"),Rect2(632,363,465,100),15,TEXT)
    text("LOCAL VERSUS  /  P1 uses primary keys. P2: arrows move/jump, comma light, period heavy, slash guard.\nP2: Enter dodge, semicolon bolt, apostrophe break. Two gamepads: device 1 = P1, device 2 = P2.\nTRAINING  /  T dummy · R reset · F3 hitboxes       SURVIVAL  /  defeat shades, recover 20 health each wave.",Rect2(74,466,1000,84),12,MUTED)
    var back: Button = button("BACK",Rect2(74,574,210,42),"back",null,true)
    back.grab_focus()

func show_credits() -> void:
    _clear_menu()
    menu_kind = "credits"
    box(Rect2(0,0,1152,648),Color(0.02,0.03,0.07,0.9),menu)
    text("VEILBOUND",Rect2(100,100,950,80),60,GOLD,null,HORIZONTAL_ALIGNMENT_CENTER)
    text("Created by Sherwin Dhaliwal",Rect2(100,220,950,40),26,TEXT,null,HORIZONTAL_ALIGNMENT_CENTER)
    text("Original characters, arena artwork, and soundtrack.\nBuilt with Godot 4.\nInterface typefaces: DejaVu Sans. License included in art/fonts/.",Rect2(100,300,950,125),16,MUTED,null,HORIZONTAL_ALIGNMENT_CENTER)
    var back: Button = button("BACK",Rect2(426,510,300,45),"back",null,true)
    back.grab_focus()

func show_result(won: bool, arcade: bool, cleared: bool, score: String, summary: String) -> void:
    _clear_menu()
    menu_kind = "result"
    box(Rect2(0,0,1152,648),Color(0.015,0.025,0.06,0.85),menu)
    text("THE VEIL IS BROKEN" if cleared else "VICTORY" if won else "FALLEN, NOT FORGOTTEN",Rect2(70,90,1012,90),46,GOLD if won else VIOLET,null,HORIZONTAL_ALIGNMENT_CENTER)
    text(score,Rect2(70,205,1012,55),32,TEXT,null,HORIZONTAL_ALIGNMENT_CENTER)
    text(summary,Rect2(130,286,892,80),17,MUTED,null,HORIZONTAL_ALIGNMENT_CENTER)
    var first: Button
    if won and arcade and not cleared:
        first = button("NEXT SEAL  →",Rect2(377,410,398,52),"next",null,true)
    elif not won:
        first = button("TRY AGAIN",Rect2(377,410,398,52),"restart",null,true)
    else:
        first = button("RETURN TO TITLE",Rect2(377,410,398,52),"title",null,true)
    if not (won and (cleared or not arcade)):
        button("RETURN TO TITLE",Rect2(377,478,398,43),"title")
    else:
        button("REMATCH",Rect2(377,478,398,43),"restart")
    first.grab_focus()

func show_survival_result(waves: int, record: int) -> void:
    show_result(false,false,false,"%d SHADES DEFEATED" % waves,"Best run: %d shades. Rise again and push further." % record)
    message_label.text = ""

func show_local_result(left_won: bool, score: String) -> void:
    show_result(true,false,false,score,"Local versus / career records unaffected")
    for child: Node in menu.get_children():
        if child is Label and child.position.y == 90:
            child.text = "PLAYER %d WINS" % (1 if left_won else 2)

func show_rebind(action: String) -> void:
    box(Rect2(0,0,1152,648),Color(0.02,0.03,0.07,0.96),menu)
    text("PRESS A KEY FOR %s" % str(InputBootstrap.TITLES[action]).to_upper(),Rect2(80,250,990,70),29,GOLD,null,HORIZONTAL_ALIGNMENT_CENTER)
    text("Esc cancels. Reserved menu keys cannot be assigned.",Rect2(80,330,990,45),16,MUTED,null,HORIZONTAL_ALIGNMENT_CENTER)

func _bar(rect: Rect2, color: Color, parent: Control, reverse: bool = false) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = rect.position
    bar.size = rect.size
    bar.show_percentage = false
    bar.max_value = 100
    bar.value = 100
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if reverse: bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
    var back := StyleBoxFlat.new()
    back.bg_color = Color("101827")
    back.set_corner_radius_all(2)
    bar.add_theme_stylebox_override("background",back)
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(2)
    bar.add_theme_stylebox_override("fill",fill)
    parent.add_child(bar)
    bar.size = rect.size
    bar.set_deferred("size",rect.size)
    return bar

func _build_combat() -> void:
    box(Rect2(0,0,1152,123),Color(0.025,0.035,0.065,0.88),combat)
    text("VEILBOUND",Rect2(37,14,220,26),12,GOLD,combat)
    text("MOONFALL SANCTUARY",Rect2(863,14,250,26),11,MUTED,combat,HORIZONTAL_ALIGNMENT_RIGHT)
    player_lag = _bar(Rect2(38,63,436,19),Color("ac6473"),combat)
    enemy_lag = _bar(Rect2(678,63,436,19),Color("ac6473"),combat,true)
    player_health = _bar(Rect2(38,63,436,19),TEAL,combat)
    enemy_health = _bar(Rect2(678,63,436,19),VIOLET,combat,true)
    var transparent := StyleBoxEmpty.new()
    player_health.add_theme_stylebox_override("background",transparent)
    enemy_health.add_theme_stylebox_override("background",transparent)
    player_stamina = _bar(Rect2(38,88,328,5),GOLD,combat)
    enemy_stamina = _bar(Rect2(786,88,328,5),GOLD,combat,true)
    player_meter = _bar(Rect2(38,600,330,9),TEAL,combat)
    enemy_meter = _bar(Rect2(784,600,330,9),VIOLET,combat,true)
    text("VEIL",Rect2(38,615,330,19),10,MUTED,combat)
    text("VEIL",Rect2(784,615,330,19),10,MUTED,combat,HORIZONTAL_ALIGNMENT_RIGHT)
    timer_label = text("60",Rect2(499,30,154,56),42,GOLD,combat,HORIZONTAL_ALIGNMENT_CENTER)
    score_label = text("○ ○    /    ○ ○",Rect2(448,91,256,25),17,TEXT,combat,HORIZONTAL_ALIGNMENT_CENTER)
    message_label = text("",Rect2(65,223,1022,88),54,GOLD,overlay,HORIZONTAL_ALIGNMENT_CENTER)
    subtitle_label = text("",Rect2(65,309,1022,40),17,TEXT,overlay,HORIZONTAL_ALIGNMENT_CENTER)
    combo_label = text("",Rect2(38,168,500,45),26,TEAL,combat)
    toast_label = text("",Rect2(326,146,500,36),23,GOLD,combat,HORIZONTAL_ALIGNMENT_CENTER)
    training_label = text("",Rect2(370,530,412,30),12,GOLD,combat,HORIZONTAL_ALIGNMENT_CENTER)
    hint_label = text("J LIGHT   K HEAVY   L GUARD   I BOLT   U BREAK   ESC PAUSE",Rect2(255,626,642,20),10,MUTED,combat,HORIZONTAL_ALIGNMENT_CENTER)
    debug_label = text("",Rect2(40,390,550,105),13,TEXT,combat)
    debug_label.hide()
    combat.hide()

func bind_fighters(new_player: FighterBase, new_enemy: FighterBase) -> void:
    player = new_player
    enemy = new_enemy
    hint_label.text = "%s LIGHT   %s HEAVY   %s GUARD   %s BOLT   %s BREAK   ESC PAUSE" % [InputBootstrap.key_text("light_attack"),InputBootstrap.key_text("heavy_attack"),InputBootstrap.key_text("block"),InputBootstrap.key_text("special_attack"),InputBootstrap.key_text("veil_break")]
    for child: Node in combat.get_children():
        if child.name == "PlayerName" or child.name == "EnemyName":
            combat.remove_child(child)
            child.queue_free()
    var player_name: Label = text(player.display_name,Rect2(38,36,436,25),16,TEAL,combat)
    player_name.name = "PlayerName"
    var enemy_name: Label = text(enemy.display_name,Rect2(678,36,436,25),16,VIOLET,combat,HORIZONTAL_ALIGNMENT_RIGHT)
    enemy_name.name = "EnemyName"
    player_health.max_value = player.max_health
    player_lag.max_value = player.max_health
    enemy_health.max_value = enemy.max_health
    enemy_lag.max_value = enemy.max_health
    player_lag.value = player.max_health
    enemy_lag.value = enemy.max_health
    combat.show()

func set_arena(index: int) -> void:
    for child: Node in combat.get_children():
        if child is Label and child.position == Vector2(863,14):
            child.text = ["MOONFALL SANCTUARY", "EMBER DAWN", "ECLIPSE CITADEL"][clampi(index,0,2)]

func set_score(left: int, right: int) -> void:
    score_label.text = "%s %s    /    %s %s" % ["●" if left>0 else "○","●" if left>1 else "○","●" if right>0 else "○","●" if right>1 else "○"]

func set_timer(value: float, training: bool = false) -> void:
    timer_label.text = "∞" if training else "%02d" % int(ceil(value))
    timer_label.add_theme_color_override("font_color", Color("ef9b9b") if value < 10 and not training else GOLD)

func set_message(title: String, subtitle: String = "") -> void:
    message_label.text = title
    subtitle_label.text = subtitle

func announce(value: String) -> void:
    toast_label.text = value
    toast_time = 1.25

func show_combo(hits: int, damage: int) -> void:
    combo_label.text = "%d %s  /  %d DAMAGE" % [hits,"HIT" if hits==1 else "HITS",damage]
    combo_time = 1.4

func set_training(behavior: int) -> void:
    training_label.text = "TRAINING  /  %s  ·  T CHANGE  ·  R RESET" % ["IDLE DUMMY","GUARD DUMMY","ACTIVE RIVAL"][behavior]

func _process(delta: float) -> void:
    toast_time = maxf(0.0,toast_time-delta)
    combo_time = maxf(0.0,combo_time-delta)
    if toast_time <= 0: toast_label.text = ""
    if combo_time <= 0: combo_label.text = ""
    if not is_instance_valid(player) or not is_instance_valid(enemy): return
    player_health.value = player.health
    enemy_health.value = enemy.health
    player_lag.value = move_toward(player_lag.value,player.health,delta*32)
    enemy_lag.value = move_toward(enemy_lag.value,enemy.health,delta*32)
    player_stamina.value = player.stamina
    enemy_stamina.value = enemy.stamina
    player_meter.value = player.meter
    enemy_meter.value = enemy.meter
    if player.meter >= 100:
        player_meter.modulate = Color(1.15,1.15,1.15) if int(Time.get_ticks_msec()/300)%2 == 0 else Color.WHITE
    else: player_meter.modulate = Color.WHITE
    if debug_label.visible:
        debug_label.text = "PLAYER  %s  HP %d  ST %.0f\nRIVAL   %s  HP %d  ST %.0f\nFPS %d" % [player.get_state_name(),player.health,player.stamina,enemy.get_state_name(),enemy.health,enemy.stamina,Engine.get_frames_per_second()]
