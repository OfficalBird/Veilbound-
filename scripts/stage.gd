extends Node2D

const BACKDROP = preload("res://art/stages/moonfall.png")
const ECLIPSE = preload("res://art/stages/eclipse.jpg")
const ARENA_SHADER = preload("res://art/shaders/arena.gdshader")
const IMPACT_FONT = preload("res://art/fonts/display.ttf")
const ATMOSPHERE: Array[Color] = [Color("77afd7"), Color("f4a66b"), Color("b184f1")]

var atmosphere: ShaderMaterial
var impact_canvas: Node2D
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
    atmosphere = ShaderMaterial.new()
    atmosphere.shader = ARENA_SHADER
    background.material = atmosphere
    add_child(background)
    impact_canvas = Node2D.new()
    impact_canvas.z_index = 4
    impact_canvas.draw.connect(_draw_impacts)
    add_child(impact_canvas)
    move_child(background, 0)
    for i: int in range(42):
        motes.append({"position":Vector2(rng.randf_range(0,1152),rng.randf_range(120,620)),"speed":rng.randf_range(8,28),"size":rng.randf_range(1,3),"phase":rng.randf()*TAU})
    set_theme(0)

func set_theme(index: int) -> void:
    theme_index = clampi(index, 0, 2)
    if background == null: return
    background.texture = ECLIPSE if index == 2 else BACKDROP
    var texture: Texture2D = background.texture
    background.scale = Vector2(1168.0/float(texture.get_width()),660.0/float(texture.get_height()))
    atmosphere.set_shader_parameter("mist_color", ATMOSPHERE[clampi(index, 0, 2)])
    background.modulate = [Color(0.8,0.9,1.0),Color(1.0,0.75,0.66),Color(0.9,0.9,1.0)][clampi(index,0,2)]

func add_impact(point: Vector2, color: Color, kind: String, amount: int = 0) -> void:
    impacts.append({"position":point,"color":color,"kind":kind,"amount":amount,"life":0.0,"seed":rng.randf()*TAU})

func _process(delta: float) -> void:
    age += delta
    atmosphere.set_shader_parameter("drift", fposmod(age, TAU * 100.0))
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
    impact_canvas.queue_redraw()

func _draw() -> void:
    for mote: Dictionary in motes:
        var point: Vector2 = mote["position"]
        var alpha: float = 0.15+0.2*(sin(age+float(mote["phase"]))+1.0)*0.5
        var color := Color(ATMOSPHERE[theme_index], alpha)
        var size: float = float(mote["size"])
        draw_rect(Rect2(point.round(), Vector2.ONE * size), color)
        if size > 2.5:
            draw_circle(point, size * 2.3, Color(color, alpha * 0.16))

func _draw_impacts() -> void:
    for effect: Dictionary in impacts:
        var point: Vector2 = effect.position
        var t: float = effect.life
        var color: Color = effect.color
        var kind: String = effect.kind
        var fade: float = 1.0 - smoothstep(0.05, 0.55, t)
        if kind in ["jump", "land", "dodge"]:
            _draw_dust(point, t, fade, effect.seed)
            continue
        var strong: bool = kind in ["parry", "guard_break", "burst"]
        var radius: float = (24.0 if strong else 12.0) + t * (180.0 if strong else 100.0)
        impact_canvas.draw_arc(point, radius, 0.0, TAU, 36, Color(color, fade * 0.56), 2.0, true)
        if strong:
            impact_canvas.draw_arc(point, radius * 0.76, 0.0, TAU, 32, Color(color, fade * 0.30), 5.0, true)
        var count: int = 16 if strong else 10
        for i: int in range(count):
            var angle: float = float(i) / count * TAU + float(effect.seed)
            var direction := Vector2(cos(angle), sin(angle))
            var speed: float = 90.0 + (i * 37) % 160
            var spark: Vector2 = point + direction * (9.0 + speed * t) + Vector2(0, t * t * 140.0)
            var tail: Vector2 = spark - direction * (8.0 + (i % 3) * 6.0) * fade
            impact_canvas.draw_line(tail, spark, Color(color, fade * 0.33), 6.0, true)
            impact_canvas.draw_line(tail, spark, Color(color.lerp(Color.WHITE, 0.60), fade), 2.0, true)
        if t < 0.12:
            var core: float = 1.0 - t / 0.12
            impact_canvas.draw_circle(point, radius * 0.8, Color(color, core * 0.20))
            impact_canvas.draw_circle(point, 6.0 * core, Color(Color.WHITE, core))
        if int(effect.amount) > 0:
            var label_position: Vector2 = point + Vector2(-9, -20 - t * 80)
            var value: String = str(effect.amount)
            impact_canvas.draw_string_outline(IMPACT_FONT, label_position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 5, Color(0.03, 0.03, 0.06, fade))
            impact_canvas.draw_string(IMPACT_FONT, label_position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(color.lerp(Color.WHITE, 0.5), fade))

func _draw_dust(point: Vector2, time: float, fade: float, seed: float) -> void:
    for i: int in range(8):
        var travel: float = (float(i) - 3.5) * (7.0 + time * 26.0)
        var lift: float = sin(float(i) * 2.0 + seed) * 7.0
        var puff: Vector2 = point + Vector2(travel, -4.0 - time * (20.0 + lift))
        var color: Color = ATMOSPHERE[theme_index].lerp(Color("c7b7ab"), 0.63)
        impact_canvas.draw_circle(puff, 3.0 + time * 12.0, Color(color, fade * 0.25))
