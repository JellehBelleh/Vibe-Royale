extends Node

var audio_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 16
var sound_cache: Dictionary = {}

func _ready() -> void:
	# Instantiate audio player pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_pool.append(player)
	
	_pregenerate_sounds()

func _pregenerate_sounds() -> void:
	sound_cache["card_play"] = _generate_tone(440.0, 880.0, 0.15, "sine")
	sound_cache["sword_hit"] = _generate_noise_hit(0.12, 1200.0)
	sound_cache["arrow_shoot"] = _generate_tone(700.0, 300.0, 0.1, "triangle")
	sound_cache["arrow_hit"] = _generate_noise_hit(0.08, 400.0)
	sound_cache["musket_shot"] = _generate_noise_hit(0.25, 200.0, true)
	sound_cache["fireball_cast"] = _generate_tone(150.0, 450.0, 0.35, "sine")
	sound_cache["explosion"] = _generate_explosion(0.4)
	sound_cache["giant_punch"] = _generate_bass_thud(0.2)
	sound_cache["dragon_breath"] = _generate_noise_hit(0.3, 800.0)
	sound_cache["skeleton_spawn"] = _generate_clicks()
	sound_cache["tower_alarm"] = _generate_tone(880.0, 440.0, 0.4, "square")
	sound_cache["elixir_tick"] = _generate_tone(523.25, 659.25, 0.06, "sine")
	sound_cache["victory"] = _generate_fanfare(true)
	sound_cache["defeat"] = _generate_fanfare(false)

func play_sfx(name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not sound_cache.has(name):
		return
	
	for player in audio_pool:
		if not player.playing:
			player.stream = sound_cache[name]
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05)
			player.play()
			return
	
	# If all busy, steal the first player
	var player = audio_pool[0]
	player.stream = sound_cache[name]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

# --- SYNTHESIS GENERATORS ---

func _generate_tone(start_freq: float, end_freq: float, duration: float, wave_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerp(start_freq, end_freq, t)
		var env = 1.0 - t
		phase += 2.0 * PI * freq / sample_rate
		var s = 0.0
		if wave_type == "sine":
			s = sin(phase)
		elif wave_type == "triangle":
			s = asin(sin(phase)) * (2.0 / PI)
		elif wave_type == "square":
			s = 1.0 if sin(phase) > 0.0 else -1.0
		
		var sample_val = int(clamp(s * env * 0.75, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_noise_hit(duration: float, freq_filter: float, has_rumble: bool = false) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	var last_val = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var env = (1.0 - t) * (1.0 - t)
		var white = randf_range(-1.0, 1.0)
		var rumble = sin(float(i) * 0.05) * 0.5 if has_rumble else 0.0
		last_val = lerp(last_val, white, clamp(freq_filter / sample_rate * 2.0, 0.05, 0.95))
		var s = (last_val + rumble) * env * 0.8
		var sample_val = int(clamp(s, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_explosion(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	var last_noise = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var env = (1.0 - t) * (1.0 - t)
		var bass = sin(float(i) * (0.04 * (1.0 - t * 0.5))) * 0.6
		var noise = randf_range(-1.0, 1.0)
		last_noise = lerp(last_noise, noise, 0.15)
		var s = (bass + last_noise * 0.7) * env
		var sample_val = int(clamp(s, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_bass_thud(duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var env = (1.0 - t) * (1.0 - t)
		var freq = lerp(120.0, 30.0, t)
		var s = sin(float(i) * 2.0 * PI * freq / sample_rate) * env * 0.9
		var sample_val = int(clamp(s, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_clicks() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var s = 0.0
		if (i >= 100 and i < 300) or (i >= 800 and i < 1000):
			s = randf_range(-0.8, 0.8)
		var sample_val = int(clamp(s, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_fanfare(is_victory: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	
	var notes = [440.0, 554.37, 659.25, 880.0] if is_victory else [440.0, 415.3, 370.0, 329.6]
	var note_dur = duration / float(notes.size())
	
	var phase = 0.0
	for i in range(num_samples):
		var time = float(i) / float(sample_rate)
		var note_idx = int(clamp(time / note_dur, 0, notes.size() - 1))
		var freq = notes[note_idx]
		var note_time = fmod(time, note_dur)
		var env = (1.0 - (note_time / note_dur) * 0.8)
		phase += 2.0 * PI * freq / sample_rate
		var s = (sin(phase) + 0.5 * sin(phase * 2.0)) * 0.5 * env
		var sample_val = int(clamp(s, -1.0, 1.0) * 127.0 + 128.0)
		data[i] = sample_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
