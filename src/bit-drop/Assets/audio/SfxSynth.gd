extends AudioStreamPlayer
class_name SfxSynth

@export var master_gain: float = 0.35

# --- Hit ---
@export var hit_freq: float = 880.0
@export var hit_decay: float = 0.06
@export var hit_pitch_drop: float = 0.35  # fraction of freq drop over decay

# --- Life lost ---
@export var life_freq_start: float = 520.0
@export var life_freq_end: float = 110.0
@export var life_time: float = 0.35
@export var life_noise: float = 0.15

# --- Game over ---
@export var over_freq1: float = 440.0
@export var over_freq2: float = 330.0
@export var over_time: float = 0.8
@export var over_vibrato_hz: float = 5.0
@export var over_vibrato_depth: float = 0.01

var gen: AudioStreamGenerator
var playb: AudioStreamGeneratorPlayback
var mix_rate: float = 44100.0

# simple voice slots (monophonic per effect type; easy + reliable)
var hit_t: float = 999.0
var hit_active: bool = false
var hit_phase: float = 0.0

var life_t: float = 999.0
var life_active: bool = false
var life_phase: float = 0.0

var over_t: float = 999.0
var over_active: bool = false
var over_phase: float = 0.0
var over_vib_phase: float = 0.0

# RNG for noise
var rng_state: int = 123456789

func _ready() -> void:
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

# --- Public API ---
func play_hit() -> void:
	hit_t = 0.0
	hit_active = true

func play_life_lost() -> void:
	life_t = 0.0
	life_active = true

func play_game_over() -> void:
	over_t = 0.0
	over_active = true

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
	out += _tick_hit(dt)
	out += _tick_life(dt)
	out += _tick_over(dt)
	# gentle soft clip
	out = tanh(out * 1.4)
	return out

func _tick_hit(dt: float) -> float:
	if not hit_active:
		return 0.0

	hit_t += dt
	if hit_t >= hit_decay:
		hit_active = false
		return 0.0

	var env: float = 1.0 - (hit_t / hit_decay)
	env = env * env  # sharper

	var f: float = hit_freq * (1.0 - hit_pitch_drop * (hit_t / hit_decay))
	f = max(40.0, f)

	hit_phase = fmod(hit_phase + f * dt, 1.0)
	var sig: float = sin(TAU * hit_phase)

	return sig * env * 0.9

func _tick_life(dt: float) -> float:
	if not life_active:
		return 0.0

	life_t += dt
	if life_t >= life_time:
		life_active = false
		return 0.0

	var env: float = 1.0 - (life_t / life_time)
	env = env * env

	var a: float = life_t / life_time
	var f: float = lerp(life_freq_start, life_freq_end, a)

	life_phase = fmod(life_phase + f * dt, 1.0)
	var tone: float = sin(TAU * life_phase)

	var n: float = _noise()
	var sig: float = tone + (n * life_noise)

	# darker over time
	sig *= lerp(1.0, 0.5, a)

	return sig * env * 0.8

func _tick_over(dt: float) -> float:
	if not over_active:
		return 0.0

	over_t += dt
	if over_t >= over_time:
		over_active = false
		return 0.0

	var env: float = 1.0 - (over_t / over_time)
	env = pow(env, 1.6)

	# two-tone “sad” interval in sequence
	var f: float = over_freq1
	if over_t > (over_time * 0.45):
		f = over_freq2

	# subtle vibrato
	over_vib_phase = fmod(over_vib_phase + over_vibrato_hz * dt, 1.0)
	var vib: float = 1.0 + sin(TAU * over_vib_phase) * over_vibrato_depth

	f *= vib

	over_phase = fmod(over_phase + f * dt, 1.0)
	var sig: float = sin(TAU * over_phase)

	return sig * env * 0.9

func _noise() -> float:
	rng_state = int((1103515245 * rng_state + 12345) & 0x7fffffff)
	var u: float = float(rng_state) / 2147483647.0
	return (u * 2.0) - 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return

	match k.keycode:
		KEY_Q:
			play_hit()
			print("Hit")
		KEY_W:
			play_life_lost()
			print("Life Lost")
		KEY_O:
			play_game_over()
			print("game over")
