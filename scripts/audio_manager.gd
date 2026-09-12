extends Node

const STREAMS := {
	"shoot": preload("res://assets/audio/shoot.ogg"),
	"power_shoot": preload("res://assets/audio/power_shoot.ogg"),
	"enemy_hit": preload("res://assets/audio/enemy_hit.ogg"),
	"enemy_death": preload("res://assets/audio/enemy_death.ogg"),
	"player_hit": preload("res://assets/audio/player_hit.ogg"),
	"shield": preload("res://assets/audio/shield.ogg"),
	"pickup": preload("res://assets/audio/pickup.ogg"),
	"wave_clear": preload("res://assets/audio/wave_clear.ogg"),
	"dash": preload("res://assets/audio/dash.ogg"),
	"venom": preload("res://assets/audio/venom.ogg"),
	"ui_click": preload("res://assets/audio/ui_click.ogg"),
	"ui_hover": preload("res://assets/audio/ui_hover.ogg"),
}

const VOLUMES := {
	"shoot": -17.0,
	"power_shoot": -14.0,
	"enemy_hit": -18.0,
	"enemy_death": -10.0,
	"player_hit": -7.0,
	"shield": -8.0,
	"pickup": -7.0,
	"wave_clear": -5.0,
	"dash": -9.0,
	"venom": -14.0,
	"ui_click": -8.0,
	"ui_hover": -18.0,
}

var pool: Array[AudioStreamPlayer] = []
var pool_cursor := 0
var ambience: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ambience = AudioStreamPlayer.new()
	var drone: AudioStreamWAV = preload("res://assets/audio/night_drone.wav").duplicate()
	drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	drone.loop_begin = 0
	drone.loop_end = 264600
	ambience.stream = drone
	ambience.volume_db = -23.0
	ambience.bus = &"Master"
	add_child(ambience)
	for i in range(18):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		pool.append(player)

func play(event_name: String, pitch_jitter: float = 0.05, volume_offset: float = 0.0) -> void:
	if not STREAMS.has(event_name) or pool.is_empty():
		return
	var player := _next_player()
	player.stop()
	player.stream = STREAMS[event_name]
	player.volume_db = float(VOLUMES.get(event_name, -10.0)) + volume_offset
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()

func start_ambience() -> void:
	if not ambience.playing:
		ambience.play()

func _next_player() -> AudioStreamPlayer:
	for offset in range(pool.size()):
		var index := (pool_cursor + offset) % pool.size()
		if not pool[index].playing:
			pool_cursor = (index + 1) % pool.size()
			return pool[index]
	var fallback := pool[pool_cursor]
	pool_cursor = (pool_cursor + 1) % pool.size()
	return fallback

func stop_all() -> void:
	ambience.stop()
	for player in pool:
		player.stop()
		player.stream = null
