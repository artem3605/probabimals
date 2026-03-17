extends Node

const SFX_POOL_SIZE := 8
const DEFAULT_FADE_SEC := 1.0
const SETTINGS_PATH := "user://audio_settings.json"

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

const KNOWN_SFX: PackedStringArray = [
	"ui_click", "ui_hover",
	"dice_roll", "dice_hold", "dice_release",
	"combo_detect", "score_tick",
	"purchase", "shop_refresh", "coin_clink",
	"round_win", "game_over",
]

const KNOWN_MUSIC: PackedStringArray = [
	"menu", "market", "combat",
]

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _current_music_name: StringName = &""
var _fade_tween: Tween
var _was_muted_before_ad := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_players()
	_load_audio_assets()
	_load_volume_settings()


func _create_players() -> void:
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = &"Music"
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.bus = &"Music"
	add_child(_music_b)

	_active_music = _music_a

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)


func _load_audio_assets() -> void:
	for sfx_name in KNOWN_SFX:
		var stream := _try_load(SFX_DIR, sfx_name)
		if stream:
			_sfx_cache[sfx_name] = stream

	for music_name in KNOWN_MUSIC:
		var stream := _try_load(MUSIC_DIR, music_name)
		if stream:
			_music_cache[music_name] = stream
		else:
			push_warning("AudioManager: failed to load music '%s'" % music_name)

	print("AudioManager: loaded %d sfx, %d music" % [_sfx_cache.size(), _music_cache.size()])
	print("AudioManager: music cache keys = ", _music_cache.keys())
	for i in AudioServer.bus_count:
		print("AudioManager: bus[%d] name=%s vol=%.1f dB mute=%s solo=%s send=%s" % [
			i, AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i),
			AudioServer.is_bus_mute(i), AudioServer.is_bus_solo(i),
			AudioServer.get_bus_send(i)])


func _try_load(dir_path: String, file_name: String) -> AudioStream:
	for ext in ["wav", "ogg", "mp3"]:
		var path := "%s%s.%s" % [dir_path, file_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


# -- SFX -------------------------------------------------------------------

func play_sfx(sfx_name: StringName, volume_db: float = 0.0) -> void:
	var stream = _sfx_cache.get(sfx_name)
	if stream == null:
		return
	var player := _get_free_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return _sfx_pool[0]


# -- Music -----------------------------------------------------------------

func play_music(music_name: StringName, fade_sec: float = DEFAULT_FADE_SEC) -> void:
	if music_name == _current_music_name:
		print("AudioManager: play_music('%s') skipped — already playing" % music_name)
		return

	var stream = _music_cache.get(music_name)
	if stream == null:
		push_warning("AudioManager: play_music('%s') — not in cache" % music_name)
		return
	_current_music_name = music_name

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var outgoing := _active_music
	var incoming := _music_b if _active_music == _music_a else _music_a
	_active_music = incoming

	_enable_loop(stream)
	incoming.stream = stream

	if not outgoing.playing:
		incoming.volume_db = 0.0
		incoming.play()
		print("AudioManager: play_music('%s') — started (no fade), playing=%s, stream=%s, bus=%s" % [
			music_name, incoming.playing, incoming.stream, incoming.bus])
	else:
		incoming.volume_db = -80.0
		incoming.play()
		_fade_tween = create_tween().set_parallel(true)
		_fade_tween.tween_property(outgoing, "volume_db", -80.0, fade_sec)
		_fade_tween.tween_property(incoming, "volume_db", 0.0, fade_sec)
		_fade_tween.chain().tween_callback(func():
			if outgoing != _active_music:
				outgoing.stop()
		)
		print("AudioManager: play_music('%s') — crossfade from '%s'" % [music_name, _current_music_name])


func stop_music(fade_sec: float = DEFAULT_FADE_SEC) -> void:
	_current_music_name = &""
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	var other := _music_b if _active_music == _music_a else _music_a
	if other.playing:
		other.stop()
	if not _active_music.playing:
		return
	var player := _active_music
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", -80.0, fade_sec)
	_fade_tween.tween_callback(func(): player.stop())


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		if stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			var length_sec := stream.get_length()
			if length_sec > 0.0:
				stream.loop_end = int(length_sec * stream.mix_rate)
	elif stream is AudioStreamOggVorbis:
		stream.loop = true


# -- Volume control --------------------------------------------------------

func set_master_volume(linear: float) -> void:
	_set_bus_volume(&"Master", linear)


func set_music_volume(linear: float) -> void:
	_set_bus_volume(&"Music", linear)


func set_sfx_volume(linear: float) -> void:
	_set_bus_volume(&"SFX", linear)


func get_master_volume() -> float:
	return _get_bus_volume(&"Master")


func get_music_volume() -> float:
	return _get_bus_volume(&"Music")


func get_sfx_volume() -> float:
	return _get_bus_volume(&"SFX")


func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))
	AudioServer.set_bus_mute(idx, linear <= 0.0)


func _get_bus_volume(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return 1.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


# -- Settings persistence -------------------------------------------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_volume_settings()


func _load_volume_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data
	set_master_volume(float(data.get("master", 1.0)))
	set_music_volume(float(data.get("music", 1.0)))
	set_sfx_volume(float(data.get("sfx", 1.0)))


func save_volume_settings() -> void:
	var data := {
		"master": snapped(get_master_volume(), 0.01),
		"music": snapped(get_music_volume(), 0.01),
		"sfx": snapped(get_sfx_volume(), 0.01),
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


# -- Ad break integration -------------------------------------------------

func pause_for_ad() -> void:
	var idx := AudioServer.get_bus_index(&"Master")
	_was_muted_before_ad = AudioServer.is_bus_mute(idx)
	AudioServer.set_bus_mute(idx, true)


func resume_after_ad() -> void:
	if not _was_muted_before_ad:
		var idx := AudioServer.get_bus_index(&"Master")
		AudioServer.set_bus_mute(idx, false)
