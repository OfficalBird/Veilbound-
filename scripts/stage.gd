extends Node2D

const BACKDROP = preload("res://art/stages/moonfall.png")
var theme_index: int = 0
var age: float = 0.0
var motes: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var background: Sprite2D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.seed = 7717
    background = Sprite2D.new()
    background.texture = BACKDROP
    background.show_behind_parent = true
    background.scale = Vector2(1168.0/float(BACKDROP.get_width()), 660.0/float(BACKDROP.get_height()))
    background.position = Vector2(576,324)
    add_child(background)
    move_child(background, 0)
    for i: int in range(42):
        motes.append({"position":Vector2(rng.randf_range(0,1152),rng.randf_range(120,620)),"speed":rng.randf_range(8,28),"size":rng.randf_range(1,3),"phase":rng.randf()*TAU})
    set_theme(0)

func set_theme(index: int) -> void:
    theme_index = index
    if background == null: return
    background.modulate = [Color(0.8,0.9,1.0),Color(1.0,0.75,0.66),Color(0.68,0.58,0.82)][clampi(index,0,2)]

func add_impact(point: Vector2, color: Color, kind: String, amount: int = 0) -> void:
    impacts.append({"position":point,"color":color,"kind":kind,"amount":amount,"life":0.0,"seed":rng.randf()*TAU})

func _process(delta: float) -> void:
    age += delta
    background.position.x = 576 + sin(age*0.13)*4
    for mote: Dictionary in motes:
        var point: Vector2 = mote["position"]
        point.x += float(mote["speed"])*delta
        point.y += sin(age + float(mote["phase"]))*delta*8
        if point.x > 1162: point.x = -10
        mote["position"] = point
    for effect: Dictionary in impacts: effect["life"] = float(effect["life"])+delta
    impacts = impacts.filter(func(effect: Dictionary) -> bool: return float(effect["life"]) < 0.55)
    queue_redraw()

func _draw() -> void:
    for mote: Dictionary in motes:
        var point: Vector2 = mote["position"]
        var alpha: float = 0.15+0.2*(sin(age+float(mote["phase"]))+1.0)*0.5
        var color := Color(0.55,0.87,1.0,alpha) if theme_index != 1 else Color(1.0,0.65,0.4,alpha)
        draw_rect(Rect2(point,Vector2.ONE*float(mote["size"])),color)
    for effect: Dictionary in impacts:
        var point: Vector2 = effect["position"]
        var t: float = float(effect["life"])
        var color: Color = effect["color"]
        color.a = maxf(0.0,1.0-t*2.0)
        if str(effect["kind"]) in ["jump","land","dodge"]:
            draw_arc(point,10+t*65,PI,TAU,16,Color(color, color.a*0.4),2)
            continue
        for i: int in range(9):
            var angle: float = float(i)/9.0*TAU+float(effect["seed"])
            var direction := Vector2(cos(angle),sin(angle))
            draw_line(point+direction*(4+t*35), point+direction*(13+t*110),color,3.0 if i%2==0 else 1.5,true)
        if t < 0.2:
            draw_circle(point,maxf(0,13-t*60),Color(1,1,1,1-t*5))
        if int(effect["amount"]) > 0:
            var font: Font = ThemeDB.fallback_font
            draw_string(font,point+Vector2(-8,-15-t*55),str(effect["amount"]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(color,color.a))
