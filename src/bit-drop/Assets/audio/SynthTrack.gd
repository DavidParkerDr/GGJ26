extends Resource
class_name SynthTrack

@export var name: String = "Track"

@export var steps: int = 16

# Roots (per-voice)
@export var root_midi_bass: int = 43
@export var root_midi_mid: int = 55
@export var root_midi_treb: int = 67

# ---- Bass ----
@export var bass_note: PackedInt32Array = PackedInt32Array()
@export var bass_acc:  PackedInt32Array = PackedInt32Array()
@export var bass_sld:  PackedInt32Array = PackedInt32Array()

# ---- Mid ----
@export var mid_note: PackedInt32Array  = PackedInt32Array()
@export var mid_acc:  PackedInt32Array  = PackedInt32Array()

# ---- Treble ----
@export var treb_note: PackedInt32Array = PackedInt32Array()
@export var treb_acc:  PackedInt32Array = PackedInt32Array()

# ---- Drums ----
@export var drum_tom: PackedInt32Array = PackedInt32Array()       # 0/1
@export var drum_cym: PackedInt32Array = PackedInt32Array()       # 0/1
@export var drum_cym_acc: PackedInt32Array = PackedInt32Array()   # 0/1

# Utility: ensure all arrays are the right length
func normalized() -> SynthTrack:
	# Make a shallow copy so you can call .normalized() safely
	var t := duplicate(true) as SynthTrack
	var n: int = max(1, t.steps)

	t.bass_note = _pad_i32(t.bass_note, n, -999)
	t.bass_acc  = _pad_i32(t.bass_acc,  n, 0)
	t.bass_sld  = _pad_i32(t.bass_sld,  n, 0)

	t.mid_note  = _pad_i32(t.mid_note,  n, -999)
	t.mid_acc   = _pad_i32(t.mid_acc,   n, 0)

	t.treb_note = _pad_i32(t.treb_note, n, -999)
	t.treb_acc  = _pad_i32(t.treb_acc,  n, 0)

	t.drum_tom  = _pad_i32(t.drum_tom,  n, 0)
	t.drum_cym  = _pad_i32(t.drum_cym,  n, 0)
	t.drum_cym_acc = _pad_i32(t.drum_cym_acc, n, 0)

	return t

static func _pad_i32(a: PackedInt32Array, n: int, fill: int) -> PackedInt32Array:
	var out := PackedInt32Array(a) # copy
	if out.size() > n:
		out.resize(n)
	elif out.size() < n:
		out.resize(n)
		for i in range(a.size(), n):
			out[i] = fill
	return out
