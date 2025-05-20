extends Node

var bus = "Music"
var player: AudioStreamPlayer
var _tween: Tween

export (Array, Resource) var old_tracks
export (Array, Resource) var new_tracks

var shuffled_tracks: = []


func _ready() -> void :
	pause_mode = PAUSE_MODE_PROCESS
	player = AudioStreamPlayer.new()
	_tween = Tween.new()
	add_child(_tween)
	add_child(player)
	player.bus = bus

	var _error = player.connect("finished", self, "on_track_finished")


func on_track_finished() -> void :
	play()


func set_shuffled_tracks() -> void :
	shuffled_tracks = []

	if ProgressData.settings.streamer_mode_tracks:
		shuffled_tracks.append_array(new_tracks.duplicate())

	if ProgressData.settings.legacy_tracks:
		shuffled_tracks.append_array(old_tracks.duplicate())

	for dlc_id in ProgressData.get_active_dlc_tracks():
		var dlc_data = ProgressData.get_dlc_data(dlc_id)
		if dlc_data:
			shuffled_tracks.append_array(dlc_data.music_tracks.duplicate())

	shuffled_tracks.shuffle()


func play(volume: float = player.volume_db) -> void :

	if shuffled_tracks.size() <= 0:

		if has_tracks_to_add():
			set_shuffled_tracks()
		else:
			player.stop()
			return

	var new_track = shuffled_tracks.pop_back()

	if new_track != player.stream:
		player.stream = new_track
	else:
		player.stream = shuffled_tracks.pop_back()

	player.volume_db = - 20
	player.play()
	tween(volume)


func has_tracks_to_add() -> bool:
	return ProgressData.settings.legacy_tracks or ProgressData.settings.streamer_mode_tracks or ProgressData.get_active_dlc_tracks().size() > 0


func tween(to: float, from: float = player.volume_db, duration: float = 1) -> void :
	if _tween.is_active():
		yield(_tween, "tween_all_completed")

	var _error_interpolate = _tween.interpolate_property(
		player, 
		"volume_db", 
		from, 
		to, 
		duration, 
		Tween.TRANS_LINEAR
	)

	var _error = _tween.start()
