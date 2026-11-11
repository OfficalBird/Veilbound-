extends Node

var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var clips: Dictionary = {}
var voice_cursor: int = 0

func _exit_tree() -> void:
    if is_instance_valid(music):
        music.stop()
        music.stream = null
    for voice: AudioStreamPlayer in voices:
        if is_instance_valid(voice):
            voice.stop()
            voice.stream = null
    clips.clear()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for i: int in range(10):
        var player := AudioStreamPlayer.new()
        add_child(player)
        voices.append(player)
    for kind: String in ["hit","block","parry","swing","dodge","jump","projectile","burst","ui","round","victory","defeat","guard_break"]:
        clips[kind] = _make_sound(kind)
    music = AudioStreamPlayer.new()
    music.stream = _make_music()
    add_child(music)
    if DisplayServer.get_name() != "headless": music.play()
    apply_volumes()

func apply_volumes() -> void:
    if is_instance_valid(music):
        music.volume_db = linear_to_db(maxf(0.001, float(SaveManager.settings["music"]))) - 9.0
        music.stream_paused = float(SaveManager.settings["music"]) <= 0.0

func play(kind: String) -> void:
    if DisplayServer.get_name() == "headless" or not clips.has(kind) or float(SaveManager.settings["sfx"]) <= 0.0: return
    var voice: AudioStreamPlayer = voices[voice_cursor % voices.size()]
    voice_cursor += 1
    voice.stream = clips[kind]
    voice.volume_db = linear_to_db(float(SaveManager.settings["sfx"])) - 5.0
    voice.pitch_scale = randf_range(0.94, 1.06) if kind in ["hit","swing","block"] else 1.0
    voice.play()

func _make_sound(kind: String) -> AudioStreamWAV:
    var length: float = 0.18
    if kind in ["parry","burst","victory","defeat"]: length = 0.65
    var rate: int = 22050
    var count: int = int(length * rate)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(kind)
    for i: int in range(count):
        var t: float = float(i) / rate
        var p: float = t / length
        var envelope: float = pow(1.0-p, 2.0) * minf(1.0,t*150.0)
        var frequency: float = 180.0
        var noise: float = rng.randf_range(-1.0,1.0)
        var wave: float
        match kind:
            "swing","dodge","jump": wave = noise * (0.5 if kind == "swing" else 0.25) + sin(t * (600.0 - p*350.0) * TAU)*0.12
            "hit","guard_break": wave = sin(TAU*t*(100.0-p*60.0))*0.55 + noise*0.35
            "block": wave = sin(TAU*t*300.0)*0.3 + sin(TAU*t*437.0)*0.2 + noise*0.2
            "parry": wave = sin(TAU*t*880.0)*0.3 + sin(TAU*t*1320.0)*0.25 + sin(TAU*t*1760.0)*0.15
            "projectile","burst": wave = sin(TAU*t*(220.0 + p*500.0))*0.3 + noise*0.23
            "victory":
                var note: int = mini(3, int(p*4.0))
                frequency = [261.63,329.63,392.0,523.25][note]
                wave = sin(t*frequency*TAU)*0.48
            "defeat": wave = sin(TAU*t*(220.0-p*110.0))*0.45
            "round": wave = sin(TAU*t*523.25)*0.35
            _: wave = sin(TAU*t*660.0)*0.25
        bytes.encode_s16(i*2, int(clampf(wave*envelope,-1.0,1.0)*24000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = bytes
    return stream

func _make_music() -> AudioStreamWAV:
    var rate: int = 22050
    var beat: float = 0.5
    var length: float = beat * 32.0
    var samples: int = int(rate*length)
    var bytes := PackedByteArray()
    bytes.resize(samples*2)
    var melody: Array[int] = [62,69,65,72,69,65,62,57,60,67,64,71,67,64,60,55,58,65,62,69,65,62,58,53,60,67,64,72,71,67,64,57]
    var roots: Array[int] = [38,36,34,36]
    for i: int in range(samples):
        var t: float = float(i)/rate
        var n: int = int(t/beat)%32
        var phase: float = fmod(t,beat)
        var frequency: float = 440.0*pow(2.0,float(melody[n]-69)/12.0)
        var root: float = 440.0*pow(2.0,float(roots[n/8]-69)/12.0)
        var pluck: float = sin(TAU*frequency*phase)*exp(-phase*8.0)*0.16 + sin(TAU*frequency*2.0*phase)*exp(-phase*14.0)*0.04
        var pad: float = (sin(TAU*root*t)+sin(TAU*root*1.5*t)+sin(TAU*root*2.0*t))*0.055
        var pulse: float = sin(TAU*(52.0*phase+4.0*(1.0-exp(-phase*30.0))))*exp(-phase*22.0)*0.1 if n%2==0 else 0.0
        var value: float = (pluck+pad+pulse)*0.8
        bytes.encode_s16(i*2,int(clampf(value,-1.0,1.0)*28000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = bytes
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = samples
    return stream
