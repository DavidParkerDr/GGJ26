extends Node
class_name TrackLibrary

static func intro() -> SynthTrack:
	var t := SynthTrack.new()
	t.name = "intro"
	t.steps = 16
	t.root_midi_bass = 43
	t.root_midi_mid = 55
	t.root_midi_treb = 67

	t.bass_note = _i([0, -999, -999, -999,  0, -999, -999, -999,  7, -999, -999, -999,  0, -999, -999, -999])
	t.bass_acc  = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])
	t.bass_sld  = _i([0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0])

	t.mid_note  = _i([-999, -999, 5, -999,  -999, -999, 3, -999,  -999, -999, 5, -999,  -999, -999, 3, -999])
	t.mid_acc   = _i([0,0,1,0,  0,0,0,0,  0,0,1,0,  0,0,0,0])

	t.treb_note = _i([-999, -999, 12, -999,  -999, -999, -999, -999,  -999, -999, 12, -999,  -999, -999, -999, -999])
	t.treb_acc  = _i([0,0,1,0,  0,0,0,0,  0,0,1,0,  0,0,0,0])

	t.drum_tom = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])
	t.drum_cym = _i([1,0,0,0,  1,0,0,0,  1,0,0,0,  1,0,0,0])
	t.drum_cym_acc = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])

	return _normalize(t)

static func relaxed() -> SynthTrack:
	var t := SynthTrack.new()
	t.name = "relaxed"
	t.steps = 16
	t.root_midi_bass = 43
	t.root_midi_mid = 55
	t.root_midi_treb = 67

	t.bass_note = _i([0, -999, 0, 3,  0, -999, 7, -999,  0, 3, -999, 7,  0, -999, 3, -999])
	t.bass_acc  = _i([1,0,0,1,  0,0,1,0,  0,1,0,1,  0,0,1,0])
	t.bass_sld  = _i([0,0,1,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])

	t.mid_note  = _i([-999, 0, -999, 5,  -999, 3, -999, 5,  -999, 0, -999, 3,  -999, 5, -999, 3])
	t.mid_acc   = _i([0,1,0,0,  0,0,0,0,  0,1,0,0,  0,0,0,0])

	t.treb_note = _i([0, -999, 12, -999,  7, -999, 12, -999,  0, -999, 12, -999,  15, -999, 12, -999])
	t.treb_acc  = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])

	t.drum_tom = _i([1,0,0,0,  0,0,1,0,  1,0,0,0,  0,0,1,0])
	t.drum_cym = _i([1,0,1,0,  1,0,1,0,  1,0,1,0,  1,0,1,0])
	t.drum_cym_acc = _i([1,0,0,0,  1,0,0,0,  1,0,0,0,  1,0,0,0])

	return _normalize(t)

static func frantic() -> SynthTrack:
	var t := SynthTrack.new()
	t.name = "frantic"
	t.steps = 16

	t.root_midi_bass = 43
	t.root_midi_mid = 55
	t.root_midi_treb = 67

	t.bass_note = _i([0, 0, -999, 3,  0, -999, 7, 7,  0, 3, 3, 7,  0, -999, 3, 5])
	t.bass_acc  = _i([1,0,0,1,  0,0,1,0,  0,1,0,1,  0,0,1,0])
	t.bass_sld  = _i([0,1,0,0,  0,0,0,1,  0,0,1,0,  0,0,0,0])

	t.mid_note  = _i([0, -999, 5, -999,  7, -999, 5, -999,  0, -999, 3, -999,  5, -999, 7, -999])
	t.mid_acc   = _i([1,0,0,0,  1,0,0,0,  1,0,0,0,  1,0,0,0])

	t.treb_note = _i([0, 12, -999, 12,  7, 12, -999, 12,  0, 12, -999, 12,  15, 12, -999, 12])
	t.treb_acc  = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])

	t.drum_tom = _i([1,0,0,0,  0,0,1,0,  1,0,0,1,  0,0,1,0])
	t.drum_cym = _i([1,1,1,1,  1,1,1,1,  1,1,1,1,  1,1,1,1])
	t.drum_cym_acc = _i([1,0,0,0,  1,0,0,0,  1,0,0,0,  1,0,0,0])

	return _normalize(t)

static func extreme() -> SynthTrack:
	var t := SynthTrack.new()
	t.name = "extreme"
	t.steps = 16

	t.root_midi_bass = 43
	t.root_midi_mid = 55
	t.root_midi_treb = 67

	t.bass_note = _i([0, 3, 0, 5,  0, 7, 0, 10,  0, 3, 0, 7,  0, 5, 3, 7])
	t.bass_acc  = _i([1,0,1,0,  0,1,0,1,  1,0,1,0,  0,1,0,1])
	t.bass_sld  = _i([0,1,1,0,  1,0,1,0,  0,1,1,0,  1,0,1,0])

	t.mid_note  = _i([0, 5, 7, 12,  0, 3, 5, 7,  0, 5, 7, 12,  15, 12, 7, 5])
	t.mid_acc   = _i([1,0,0,0,  1,0,0,0,  1,0,0,0,  1,0,0,0])

	t.treb_note = _i([12, -999, 12, -999,  15, -999, 12, -999,  12, -999, 19, -999,  15, -999, 12, -999])
	t.treb_acc  = _i([1,0,0,0,  0,0,0,0,  1,0,0,0,  0,0,0,0])

	t.drum_tom = _i([1,0,0,1,  0,0,1,0,  1,0,0,1,  0,1,0,1])
	t.drum_cym = _i([1,1,1,1,  1,1,1,1,  1,1,1,1,  1,1,1,1])
	t.drum_cym_acc = _i([1,0,0,0,  0,0,1,0,  1,0,0,0,  0,0,1,0])

	return _normalize(t)

# -------- helpers --------
static func _i(vals: Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(vals.size())
	for i in range(vals.size()):
		out[i] = int(vals[i])
	return out

static func _normalize(t: SynthTrack) -> SynthTrack:
	# Ensure all arrays match t.steps (pad/truncate)
	var n: int = max(1, t.steps)

	t.bass_note = _pad(t.bass_note, n, -999)
	t.bass_acc  = _pad(t.bass_acc,  n, 0)
	t.bass_sld  = _pad(t.bass_sld,  n, 0)

	t.mid_note  = _pad(t.mid_note,  n, -999)
	t.mid_acc   = _pad(t.mid_acc,   n, 0)

	t.treb_note = _pad(t.treb_note, n, -999)
	t.treb_acc  = _pad(t.treb_acc,  n, 0)

	t.drum_tom  = _pad(t.drum_tom,  n, 0)
	t.drum_cym  = _pad(t.drum_cym,  n, 0)
	t.drum_cym_acc = _pad(t.drum_cym_acc, n, 0)
	return t

static func _pad(a: PackedInt32Array, n: int, fill: int) -> PackedInt32Array:
	var out := PackedInt32Array(a)
	out.resize(n)
	for i in range(min(a.size(), n), n):
		out[i] = fill
	return out
