extends AudioStreamPlayer
class_name JingleSynth

# ---------------------------
# Public controls
# ---------------------------
@export var master_gain: float = 0.35

@export var attack: float = 0.004
@export var release: float = 0.14

@export var vibrato_hz: float = 6.0
@export var vibrato_depth: float = 0.004   # ~0.4%

@export var tone_mix_2nd: float = 0.25     # 2nd harmonic mix (sparkle)
@export var tone_mix_3rd: float = 0.08     # small 3rd harmonic

@export var hp_cutoff_hz: float = 220.0    # keep low end out of jingles

# Default jingle pitch center (can be overridden per jingle)
@export var default_root_midi: int = 79    # G5-ish; bright and "stinger-y"

# ---------------------------
# Generator
# ---------------------------
var gen: AudioStreamGenerator
var playb: AudioStreamGeneratorPlayback
var mix_rate: float = 44100.0

# ---------------------------
# Jingle sequencing state
# ---------------------------
var active: bool = false
var note_idx: int = 0
var note_t: float = 0.0
var env: float = 0.0
var gate: bool = false

var phase: float = 0.0
var vib_phase: float = 0.0
var freq_hz: float = 440.0

var root_midi: int = 79
var notes: PackedInt32Array = PackedInt32Array()     # offsets from root, -999 = rest
var durs: PackedFloat32Array = PackedFloat32Array()  # seconds per step

# High-pass helper state (via low-pass subtraction)
var lp_state: float = 0.0

# RNG for tiny detune variance
var rng_state: int = 123456789
@export var detune_amount: float = 0.004  # ±0.4% random detune per note (0 disables)

func _ready() -> void:
	# Ensure generator exists
	if stream == null or not (stream is AudioStreamGenerator):
		gen = AudioStreamGenerator.new()
		stream = gen
	else:
		gen = stream as AudioStreamGenerator

	gen.mix_rate = 44100
	gen.buffer_length = 0.1
	mix_rate = float(gen.mix_rate)

	play()
	playb = get_stream_playback() as AudioStreamGeneratorPlayback

# ---------------------------
# Public API for game events
# ---------------------------

func play_level_complete() -> void:
	# triumphant rise + tag (minor pentatonic-friendly)
	root_midi = default_root_midi
	notes = PackedInt32Array([0, 3, 7, 10, 12, -999, 12, 7, 12])
	durs  = PackedFloat32Array([0.10,0.10,0.10,0.10,0.18, 0.06, 0.10,0.10,0.22])
	_start()

func play_skill_move() -> void:
	# quick flourish
	root_midi = default_root_midi
	notes = PackedInt32Array([12, 10, 7, 10, 12])
	durs  = PackedFloat32Array([0.06,0.06,0.06,0.06,0.12])
	_start()

func play_power_up() -> void:
	# activation rise + hold
	root_midi = default_root_midi
	notes = PackedInt32Array([0, 7, 10, 12, 12, -999, 12])
	durs  = PackedFloat32Array([0.08,0.08,0.08,0.14,0.10, 0.06, 0.24])
	_start()

func play_bonus() -> void:
	# playful “bling” syncopation
	root_midi = default_root_midi
	notes = PackedInt32Array([12, -999, 12, 10, -999, 10, 7, 10, 12])
	durs  = PackedFloat32Array([0.07,0.03, 0.07,0.07, 0.03, 0.07,0.07,0.07,0.18])
	_start()

# Optional: play a custom jingle from code
# offsets: semitone offsets from root_midi, -999 = rest
# durations: seconds per entry
func play_custom(root: int, offsets: PackedInt32Array, durations: PackedFloat32Array) -> void:
	root_midi = root
	notes = offsets
	durs = durations
	_start()
	
func play_game_start() -> void:
	# ~2 second start stinger
	# Fast motif + lift + short held tag
	root_midi = default_root_midi  # e.g. 79 (G5)

	notes = PackedInt32Array([
		# Motif
		0, 3, 7, 10, -999,
		# Lift
		7, 10, 12, -999,
		# Tag
		12
	])

	durs = PackedFloat32Array([
		# Motif
		0.14, 0.14, 0.14, 0.18, 0.08,
		# Lift
		0.14, 0.16, 0.22, 0.08,
		# Tag
		0.55
	])

	_start()


# Stop immediately (with a short release)
func stop_jingle() -> void:
	active = false
	gate = false

# ---------------------------
# Audio generation
# ---------------------------

func _process(_delta: float) -> void:
	if playb == null:
		return

	var frames: int = playb.get_frames_available()
	var dt: float = 1.0 / mix_rate

	for i in range(frames):
		var s: float = _tick(dt) * master_gain
		playb.push_frame(Vector2(s, s))

func _tick(dt: float) -> float:
	var out: float = 0.0
	out += _tick_jingle(dt)
	# gentle soft clip
	out = tanh(out * 1.2)
	return out

func _tick_jingle(dt: float) -> float:
	# If not active, let envelope release to zero cleanly
	if not active and env <= 0.00001:
		return 0.0

	# Advance note timing only while active
	if active:
		note_t += dt

		var dur: float = durs[note_idx]
		if note_t >= dur:
			note_t -= dur
			note_idx += 1

			var n: int = min(notes.size(), durs.size())
			if note_idx >= n:
				# done: release
				active = false
				gate = false
			else:
				# next note
				env = 0.0
				_set_note(notes[note_idx])

	# Envelope (AR)
	env = _env_ar(env, gate, attack, release, dt)

	# If envelope is effectively silent, skip work
	if env <= 0.00001:
		return 0.0

	# Vibrato
	vib_phase = fmod(vib_phase + vibrato_hz * dt, 1.0)
	var vib: float = 1.0 + sin(TAU * vib_phase) * vibrato_depth

	var f: float = max(20.0, freq_hz * vib)

	# Oscillator: sine + harmonics for sparkle
	phase = fmod(phase + f * dt, 1.0)
	var s1: float = sin(TAU * phase)
	var s2: float = sin(TAU * 2.0 * phase) * tone_mix_2nd
	var s3: float = sin(TAU * 3.0 * phase) * tone_mix_3rd
	var sig: float = s1 + s2 + s3

	# Simple high-pass (sig - lowpass(sig))
	var hp: float = _highpass(sig, hp_cutoff_hz, dt)

	return hp * env

# ---------------------------
# Sequencer helpers
# ---------------------------

func _start() -> void:
	var n: int = min(notes.size(), durs.size())
	if n <= 0:
		return

	active = true
	note_idx = 0
	note_t = 0.0
	env = 0.0
	phase = 0.0
	vib_phase = 0.0

	_set_note(notes[0])

func _set_note(offset: int) -> void:
	if offset == -999:
		gate = false
		return

	gate = true

	var base: float = _midi_to_hz(root_midi + offset)

	# tiny per-note detune for life (optional)
	if detune_amount > 0.0:
		var d: float = randf_range(-detune_amount, detune_amount)
		base *= (1.0 + d)

	freq_hz = base

func _midi_to_hz(m: int) -> float:
	return 440.0 * pow(2.0, (float(m) - 69.0) / 12.0)

func _env_ar(e: float, g: bool, a: float, r: float, dt: float) -> float:
	if g:
		if a <= 0.00001:
			return 1.0
		return min(1.0, e + dt / a)
	else:
		if r <= 0.00001:
			return 0.0
		return max(0.0, e - dt / r)

func _highpass(x: float, cutoff: float, dt: float) -> float:
	# lowpass coefficient
	var c: float = max(20.0, cutoff)
	var rc: float = 1.0 / (TAU * c)
	var alpha: float = dt / (rc + dt)   # LP alpha
	lp_state = lp_state + alpha * (x - lp_state)
	return x - lp_state


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return

	match k.keycode:
		KEY_1:
			play_bonus()
		KEY_2:
			play_power_up()
		KEY_3:
			play_level_complete()
		KEY_4:
			play_skill_move()
		KEY_5:
			play_game_start()
