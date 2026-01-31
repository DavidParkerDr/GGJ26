extends AudioStreamPlayer
##
## RubberSynthPlayer.gd
## Godot 4.6 (GDScript) procedural music player using TrackLibrary tracks.
##
## REQUIREMENTS:
##   - res://audio/SynthTrack.gd   (extends Resource, class_name SynthTrack)
##   - res://audio/TrackLibrary.gd (your file; class_name TrackLibrary)
##
## SETUP:
##   1) Add AudioStreamPlayer node
##   2) Set Stream = AudioStreamGenerator (Inspector -> Stream -> New AudioStreamGenerator)
##   3) Attach this script
##   4) Run
##

# ---------------- Track selection ----------------
enum Mood { INTRO, RELAXED, FRANTIC, EXTREME }
@export var start_mood: Mood = Mood.INTRO

enum SwapMode { NEXT_STEP, NEXT_BAR }
@export var swap_mode: SwapMode = SwapMode.NEXT_BAR

# ---------------- Sequencer ----------------
@export var bpm: float = 122.0
@export var steps_per_beat: int = 4       # 4 => 16th notes
@export var swing: float = 0.06

# ---------------- Mix / tone ----------------
@export var master_gain: float = 0.20
@export var drive: float = 1.6

@export var bass_level: float = 1.0
@export var mid_level: float = 0.55
@export var treb_level: float = 0.45
@export var drum_level: float = 0.75

# Gentle master low-pass to reduce harshness
@export var master_lp_cutoff: float = 9000.0
@export var master_lp_res: float = 0.10

# ---------------- Bass voice ----------------
@export var bass_glide_time: float = 0.06
@export var bass_osc_mix_saw: float = 1.0
@export var bass_osc_mix_square: float = 0.10
@export var bass_pulse_width: float = 0.45

@export var bass_amp_attack: float = 0.004
@export var bass_amp_release: float = 0.11

@export var bass_cutoff_base: float = 360.0
@export var bass_cutoff_env: float = 1400.0
@export var bass_res: float = 0.82
@export var bass_filt_attack: float = 0.012
@export var bass_filt_release: float = 0.18

@export var bass_accent_gain: float = 1.25
@export var bass_accent_cut_boost: float = 1.35

@export var bass_lfo_hz: float = 0.45
@export var bass_lfo_depth: float = 45.0

# ---------------- Mid voice (band-pass lead) ----------------
@export var mid_glide_time: float = 0.02
@export var mid_mix_saw: float = 0.75
@export var mid_mix_square: float = 0.35
@export var mid_pulse_width: float = 0.35

@export var mid_amp_attack: float = 0.003
@export var mid_amp_release: float = 0.14

@export var mid_center_base: float = 900.0
@export var mid_center_env: float = 1200.0
@export var mid_res: float = 0.70
@export var mid_filt_attack: float = 0.010
@export var mid_filt_release: float = 0.22

@export var mid_accent_gain: float = 1.15
@export var mid_accent_center_boost: float = 1.15

# ---------------- Treble voice (sparkle) ----------------
@export var treb_mix_pulse: float = 0.8
@export var treb_mix_noise: float = 0.35
@export var treb_pulse_width: float = 0.30

@export var treb_amp_attack: float = 0.002
@export var treb_amp_release: float = 0.060

@export var treb_hp_cutoff: float = 2200.0
@export var treb_hp_res: float = 0.25
@export var treb_accent_gain: float = 1.25

# ---------------- Drums ----------------
# Tom = sine + pitch drop + one-shot envelope
@export var tom_gain: float = 0.9
@export var tom_attack: float = 0.002
@export var tom_decay: float = 0.22
@export var tom_start_hz: float = 170.0
@export var tom_end_hz: float = 85.0
@export var tom_pitch_drop_time: float = 0.12
@export var tom_drive: float = 1.3

# Cymbal = noise + high-pass + one-shot envelope
@export var cym_gain: float = 0.55
@export var cym_attack: float = 0.002
@export var cym_decay: float = 0.075
@export var cym_hp_cutoff: float = 3800.0
@export var cym_hp_res: float = 0.20
@export var cym_tone_mix: float = 0.08
@export var cym_tone_hz: float = 4200.0


# ========================= Internal state =========================
var gen: AudioStreamGenerator
var playb: AudioStreamGeneratorPlayback
var mix_rate: float = 44100.0

# clock
var step_index: int = 0
var step_time_accum: float = 0.0
var step_dur: float = 0.0

# tracks (built once, swapped seamlessly)
var current_track: SynthTrack = null
var pending_track: SynthTrack = null

@onready var track_intro: SynthTrack = TrackLibrary.intro()
@onready var track_relaxed: SynthTrack = TrackLibrary.relaxed()
@onready var track_frantic: SynthTrack = TrackLibrary.frantic()
@onready var track_extreme: SynthTrack = TrackLibrary.extreme()

# RNG
var rng_state: int = 123456789

# master filter state (SVF)
var master_lp: float = 0.0
var master_bp: float = 0.0

# bass SVF state
var bass_lp: float = 0.0
var bass_bp: float = 0.0

# mid SVF state
var mid_lp: float = 0.0
var mid_bp: float = 0.0

# treble SVF state
var treb_lp: float = 0.0
var treb_bp: float = 0.0

# cymbal SVF state
var cym_lp: float = 0.0
var cym_bp: float = 0.0

# oscillator + envelope states
var bass_phase: float = 0.0
var bass_freq_target: float = 110.0
var bass_freq_current: float = 110.0
var bass_amp_env: float = 0.0
var bass_amp_gate: bool = false
var bass_filt_env: float = 0.0
var bass_filt_gate: bool = false
var bass_lfo_phase: float = 0.0

var mid_phase: float = 0.0
var mid_freq_target: float = 220.0
var mid_freq_current: float = 220.0
var mid_amp_env: float = 0.0
var mid_amp_gate: bool = false
var mid_filt_env: float = 0.0
var mid_filt_gate: bool = false

var treb_phase: float = 0.0
var treb_freq_target: float = 880.0
var treb_amp_env: float = 0.0
var treb_amp_gate: bool = false

var tom_phase: float = 0.0
var tom_hit_t: float = 999.0
var tom_active: bool = false

var cym_phase: float = 0.0
var cym_hit_t: float = 999.0
var cym_active: bool = false


# ========================= Public API =========================
func set_track(track: SynthTrack) -> void:
	if track == null:
		return
	pending_track = track

func set_mood(m: Mood) -> void:
	match m:
		Mood.INTRO:
			set_track(track_intro)
		Mood.RELAXED:
			set_track(track_relaxed)
		Mood.FRANTIC:
			set_track(track_frantic)
		Mood.EXTREME:
			set_track(track_extreme)

# Optional: map 0..1 to a mood
func set_intensity(x: float) -> void:
	var v: float = clamp(x, 0.0, 1.0)
	if v < 0.2:
		set_mood(Mood.INTRO)
	elif v < 0.55:
		set_mood(Mood.RELAXED)
	elif v < 0.8:
		set_mood(Mood.FRANTIC)
	else:
		set_mood(Mood.EXTREME)

var music_bus := AudioServer.get_bus_index("Music")
var reverb: AudioEffectReverb = null

# ========================= Lifecycle =========================
func _ready() -> void:
	# Ensure stream is an AudioStreamGenerator
	if stream == null or not (stream is AudioStreamGenerator):
		gen = AudioStreamGenerator.new()
		stream = gen
	else:
		gen = stream as AudioStreamGenerator

	for i in range(AudioServer.get_bus_effect_count(music_bus)):
		var fx = AudioServer.get_bus_effect(music_bus, i)
		if fx is AudioEffectReverb:
			reverb = fx
			break

	if reverb == null:
		push_warning("No reverb effect found on Music bus")
	gen.mix_rate = 44100
	gen.buffer_length = 0.2
	mix_rate = float(gen.mix_rate)

	play()
	playb = get_stream_playback() as AudioStreamGeneratorPlayback

	step_dur = 1.0 / ((bpm / 60.0) * float(steps_per_beat))

	# Pick start track
	match start_mood:
		Mood.INTRO:
			current_track = track_intro
		Mood.RELAXED:
			current_track = track_relaxed
		Mood.FRANTIC:
			current_track = track_frantic
		Mood.EXTREME:
			current_track = track_extreme

	step_index = 0
	step_time_accum = 0.0
	_trigger_step(0)


func _process(_delta: float) -> void:
	if playb == null:
		return

	var frames: int = playb.get_frames_available()
	for i in range(frames):
		var s: float = _tick(1.0 / mix_rate)
		playb.push_frame(Vector2(s, s))


# ========================= Main tick =========================
func _tick(dt: float) -> float:
	if current_track == null:
		return 0.0

	# Clock with swing
	step_time_accum += dt
	var this_step: float = step_dur
	if (step_index % 2) == 1:
		this_step *= (1.0 + swing)
	else:
		this_step *= (1.0 - swing)

	if step_time_accum >= this_step:
		step_time_accum -= this_step
		var steps: int = max(1, current_track.steps)
		step_index = (step_index + 1) % steps

		# Apply pending swaps on boundary
		if pending_track != null:
			if swap_mode == SwapMode.NEXT_STEP:
				_apply_pending_track()
			elif swap_mode == SwapMode.NEXT_BAR and step_index == 0:
				_apply_pending_track()

		_trigger_step(step_index)

	var bass: float = _bass_tick(dt) * bass_level
	var mid: float = _mid_tick(dt) * mid_level
	var treb: float = _treb_tick(dt) * treb_level
	var drums: float = _drum_tick(dt) * drum_level

	var mix: float = bass + mid + treb + drums

	# Gentle master low-pass
	if master_lp_cutoff > 0.0:
		var c: float = clamp(master_lp_cutoff, 200.0, mix_rate * 0.45)
		mix = _svf_lp_master(mix, c, master_lp_res, dt)

	# Soft clip
	mix = tanh(mix * drive)

	return mix * master_gain


func _apply_pending_track() -> void:
	current_track = pending_track
	pending_track = null


# ========================= Step trigger =========================
func _trigger_step(idx: int) -> void:
	# Bass
	var bn: int = current_track.bass_note[idx]
	if bn == -999:
		bass_amp_gate = false
		bass_filt_gate = false
	else:
		var slide: bool = (current_track.bass_sld[idx] == 1)
		if not slide:
			bass_amp_env = 0.0
			bass_filt_env = 0.0
		bass_amp_gate = true
		bass_filt_gate = true
		bass_freq_target = _midi_to_hz(current_track.root_midi_bass + bn)

	# Mid
	var mn: int = current_track.mid_note[idx]
	if mn == -999:
		mid_amp_gate = false
		mid_filt_gate = false
	else:
		mid_amp_env = 0.0
		mid_filt_env = 0.0
		mid_amp_gate = true
		mid_filt_gate = true
		mid_freq_target = _midi_to_hz(current_track.root_midi_mid + mn)

	# Treble
	var tn: int = current_track.treb_note[idx]
	if tn == -999:
		treb_amp_gate = false
	else:
		treb_amp_env = 0.0
		treb_amp_gate = true
		treb_freq_target = _midi_to_hz(current_track.root_midi_treb + tn)

	# Drums
	if current_track.drum_tom[idx] == 1:
		tom_hit_t = 0.0
		tom_active = true

	if current_track.drum_cym[idx] == 1:
		cym_hit_t = 0.0
		cym_active = true


# ========================= Voices =========================
func _bass_tick(dt: float) -> float:
	# Glide
	if bass_glide_time > 0.0001:
		var k: float = min(1.0, dt / bass_glide_time)
		bass_freq_current = lerp(bass_freq_current, bass_freq_target, k)
	else:
		bass_freq_current = bass_freq_target

	# Envelopes
	bass_amp_env = _env_ar(bass_amp_env, bass_amp_gate, bass_amp_attack, bass_amp_release, dt)
	bass_filt_env = _env_ar(bass_filt_env, bass_filt_gate, bass_filt_attack, bass_filt_release, dt)

	# LFO
	bass_lfo_phase = fmod(bass_lfo_phase + bass_lfo_hz * dt, 1.0)
	var lfo: float = sin(TAU * bass_lfo_phase) * bass_lfo_depth

	# Osc
	bass_phase = fmod(bass_phase + (bass_freq_current * dt), 1.0)
	var saw: float = (2.0 * bass_phase) - 1.0
	var sq: float = 1.0 if bass_phase < bass_pulse_width else -1.0
	var osc: float = (bass_osc_mix_saw * saw) + (bass_osc_mix_square * sq)

	# Accent
	var is_acc: bool = (current_track.bass_acc[step_index] == 1)
	var amp_mul: float = bass_accent_gain if is_acc else 1.0

	# Filter cutoff
	var cutoff: float = bass_cutoff_base + (bass_filt_env * bass_cutoff_env) + lfo
	if is_acc:
		cutoff *= bass_accent_cut_boost
	cutoff = clamp(cutoff, 70.0, mix_rate * 0.45)

	var lp: float = _svf_lp_bass(osc, cutoff, bass_res, dt)
	return lp * bass_amp_env * amp_mul


func _mid_tick(dt: float) -> float:
	# Glide
	if mid_glide_time > 0.0001:
		var k: float = min(1.0, dt / mid_glide_time)
		mid_freq_current = lerp(mid_freq_current, mid_freq_target, k)
	else:
		mid_freq_current = mid_freq_target

	# Envelopes
	mid_amp_env = _env_ar(mid_amp_env, mid_amp_gate, mid_amp_attack, mid_amp_release, dt)
	mid_filt_env = _env_ar(mid_filt_env, mid_filt_gate, mid_filt_attack, mid_filt_release, dt)

	# Osc
	mid_phase = fmod(mid_phase + (mid_freq_current * dt), 1.0)
	var saw: float = (2.0 * mid_phase) - 1.0
	var sq: float = 1.0 if mid_phase < mid_pulse_width else -1.0
	var osc: float = (mid_mix_saw * saw) + (mid_mix_square * sq)

	# Accent
	var is_acc: bool = (current_track.mid_acc[step_index] == 1)
	var amp_mul: float = mid_accent_gain if is_acc else 1.0

	# “Formant” center
	var center: float = mid_center_base + (mid_filt_env * mid_center_env)
	if is_acc:
		center *= mid_accent_center_boost
	center = clamp(center, 120.0, mix_rate * 0.45)

	var bp: float = _svf_bp_mid(osc, center, mid_res, dt)

	# Low trim
	var low_trim: float = clamp((mid_freq_current - 120.0) / 600.0, 0.35, 1.0)
	return bp * mid_amp_env * amp_mul * low_trim


func _treb_tick(dt: float) -> float:
	treb_amp_env = _env_ar(treb_amp_env, treb_amp_gate, treb_amp_attack, treb_amp_release, dt)

	# Keep treble crisp by snapping to target
	# (If you want glide, introduce a treb_glide_time like the others.)
	var freq: float = treb_freq_target

	treb_phase = fmod(treb_phase + (freq * dt), 1.0)
	var pulse: float = 1.0 if treb_phase < treb_pulse_width else -1.0
	var n: float = _noise()
	var src: float = (pulse * treb_mix_pulse) + (n * treb_mix_noise)

	# Accent
	var is_acc: bool = (current_track.treb_acc[step_index] == 1)
	var amp_mul: float = treb_accent_gain if is_acc else 1.0

	# High-pass
	var hp: float = _svf_hp_treb(src, clamp(treb_hp_cutoff, 400.0, mix_rate * 0.45), treb_hp_res, dt)

	return hp * treb_amp_env * amp_mul


func _drum_tick(dt: float) -> float:
	var out: float = 0.0

	# Tom
	if tom_active:
		tom_hit_t += dt
		var env: float = _env_ad_shot(tom_hit_t, tom_attack, tom_decay)
		if env <= 0.0:
			tom_active = false
		else:
			var alpha: float = 0.0
			if tom_pitch_drop_time > 0.0001:
				alpha = clamp(tom_hit_t / tom_pitch_drop_time, 0.0, 1.0)
			var hz: float = lerp(tom_start_hz, tom_end_hz, alpha)

			tom_phase = fmod(tom_phase + (hz * dt), 1.0)
			var sig: float = sin(TAU * tom_phase) * env * tom_gain
			sig = tanh(sig * tom_drive)
			out += sig

	# Cymbal
	if cym_active:
		cym_hit_t += dt
		var env2: float = _env_ad_shot(cym_hit_t, cym_attack, cym_decay)
		if env2 <= 0.0:
			cym_active = false
		else:
			var is_acc: bool = (current_track.drum_cym_acc[step_index] == 1)
			var mul: float = 1.15 if is_acc else 0.90

			cym_phase = fmod(cym_phase + (cym_tone_hz * dt), 1.0)
			var tone: float = sin(TAU * cym_phase) * cym_tone_mix
			var src2: float = _noise() + tone

			var hp2: float = _svf_hp_cym(src2, clamp(cym_hp_cutoff, 800.0, mix_rate * 0.45), cym_hp_res, dt)
			out += hp2 * env2 * cym_gain * mul

	return out


# ========================= Utilities =========================
func _midi_to_hz(m: int) -> float:
	return 440.0 * pow(2.0, (float(m) - 69.0) / 12.0)

func _env_ar(env: float, gate: bool, a: float, r: float, dt: float) -> float:
	if gate:
		if a <= 0.00001:
			return 1.0
		return min(1.0, env + dt / a)
	else:
		if r <= 0.00001:
			return 0.0
		return max(0.0, env - dt / r)

# One-shot attack/decay by "time since hit"
func _env_ad_shot(t: float, a: float, d: float) -> float:
	if t < 0.0:
		return 0.0
	if a <= 0.00001:
		if d <= 0.00001:
			return 0.0
		return max(0.0, 1.0 - (t / d))

	if t < a:
		return clamp(t / a, 0.0, 1.0)

	var td: float = t - a
	if d <= 0.00001:
		return 0.0
	return max(0.0, 1.0 - (td / d))

func _noise() -> float:
	rng_state = int((1103515245 * rng_state + 12345) & 0x7fffffff)
	var u: float = float(rng_state) / 2147483647.0
	return (u * 2.0) - 1.0


# ========================= SVF filters =========================
func _svf_lp_bass(x: float, cutoff_hz: float, res: float, dt: float) -> float:
	var f: float = 2.0 * sin(PI * cutoff_hz * dt)
	var q: float = clamp(res, 0.0, 0.999)
	var hp: float = x - bass_lp - (q * bass_bp)
	bass_bp += f * hp
	bass_lp += f * bass_bp
	return bass_lp

func _svf_bp_mid(x: float, cutoff_hz: float, res: float, dt: float) -> float:
	var f: float = 2.0 * sin(PI * cutoff_hz * dt)
	var q: float = clamp(res, 0.0, 0.999)
	var hp: float = x - mid_lp - (q * mid_bp)
	mid_bp += f * hp
	mid_lp += f * mid_bp
	return mid_bp

func _svf_hp_treb(x: float, cutoff_hz: float, res: float, dt: float) -> float:
	var f: float = 2.0 * sin(PI * cutoff_hz * dt)
	var q: float = clamp(res, 0.0, 0.999)
	var hp: float = x - treb_lp - (q * treb_bp)
	treb_bp += f * hp
	treb_lp += f * treb_bp
	return hp

func _svf_hp_cym(x: float, cutoff_hz: float, res: float, dt: float) -> float:
	var f: float = 2.0 * sin(PI * cutoff_hz * dt)
	var q: float = clamp(res, 0.0, 0.999)
	var hp: float = x - cym_lp - (q * cym_bp)
	cym_bp += f * hp
	cym_lp += f * cym_bp
	return hp

func _svf_lp_master(x: float, cutoff_hz: float, res: float, dt: float) -> float:
	var f: float = 2.0 * sin(PI * cutoff_hz * dt)
	var q: float = clamp(res, 0.0, 0.999)
	var hp: float = x - master_lp - (q * master_bp)
	master_bp += f * hp
	master_lp += f * master_bp
	return master_lp


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return

	match k.keycode:
		KEY_I:
			set_mood(Mood.INTRO)
			print("Intro")
		KEY_R:
			set_mood(Mood.RELAXED)
			print("Relaxed")
		KEY_F:
			set_mood(Mood.FRANTIC)
			print("Frantic")
		KEY_E:
			set_mood(Mood.EXTREME)
			print("Extreme")
