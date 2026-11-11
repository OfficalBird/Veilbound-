extends RefCounted
class_name VeilMoves

const LIGHTS: Array[Dictionary] = [
    {"name":"Quick cut", "damage":10, "windup":0.08, "active":0.10, "recovery":0.18, "cooldown":0.40, "reach":116.0, "knockback":120.0, "hitstun":0.23, "cost":0.0, "guard":10.0},
    {"name":"Cross cut", "damage":12, "windup":0.10, "active":0.10, "recovery":0.20, "cooldown":0.40, "reach":126.0, "knockback":145.0, "hitstun":0.25, "cost":0.0, "guard":12.0},
    {"name":"Veil cleaver", "damage":16, "windup":0.14, "active":0.12, "recovery":0.28, "cooldown":0.54, "reach":142.0, "knockback":370.0, "hitstun":0.36, "cost":0.0, "guard":18.0}
]
const HEAVY: Dictionary = {"name":"Sundering strike", "damage":26, "windup":0.24, "active":0.14, "recovery":0.36, "cooldown":0.78, "reach":158.0, "knockback":440.0, "hitstun":0.40, "cost":24.0, "guard":34.0}
const SPECIAL: Dictionary = {"name":"Veil bolt", "damage":16, "windup":0.20, "active":0.08, "recovery":0.30, "cooldown":0.90, "reach":0.0, "knockback":230.0, "hitstun":0.27, "cost":30.0, "guard":20.0}
const BURST: Dictionary = {"name":"Veil break", "damage":42, "windup":0.34, "active":0.18, "recovery":0.45, "cooldown":1.40, "reach":208.0, "knockback":580.0, "hitstun":0.65, "cost":0.0, "guard":75.0}

static func attack(kind: String, step: int = 0) -> Dictionary:
    var data: Dictionary
    match kind:
        "heavy": data = HEAVY.duplicate()
        "special": data = SPECIAL.duplicate()
        "burst": data = BURST.duplicate()
        _: data = LIGHTS[clampi(step, 0, 2)].duplicate()
    data["kind"] = kind
    return data
