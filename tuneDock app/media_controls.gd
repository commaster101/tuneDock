extends Control
@export var audio_master:AudioMaster
@export var song_manager:SongManager
@export var song_progress_bar:HSlider
@export var play_pause:TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not song_progress_bar.has_focus() && Engine.get_process_frames() % 20 == 0:
		song_progress_bar.max_value = audio_master.get_duration()
		song_progress_bar.value = audio_master.get_playback_position()
	if !audio_master.is_paused():
		song_progress_bar.value += delta
	
	if song_progress_bar.value == song_progress_bar.max_value && !song_progress_bar.has_focus() && !audio_master.is_paused():
		song_progress_bar.value = 0.0
		_on_next_pressed()

func _on_song_progress_bar_drag_ended(value_changed: bool) -> void:
	if value_changed:
		audio_master.set_playback_position(song_progress_bar.value)
	get_viewport().gui_release_focus()


func _on_play_pause_toggled(toggled_on: bool) -> void:
	audio_master.pause(toggled_on)


func _on_previous_pressed() -> void:
	song_manager.play_prev()


func _on_next_pressed() -> void:
	song_manager.play_next()
