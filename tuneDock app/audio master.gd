class_name AudioMaster extends Node
@export var audio:AudioStreamPlayer
@export var playing_song_display:Node
@onready var music_player = Engine.get_singleton("MusicPlayer") if Engine.has_singleton("MusicPlayer") else null

func get_playback_position() -> float:
	if OS.get_name() == "Android":
		return music_player.get_position()
	else:
		return audio.get_playback_position()

func get_duration() -> float:
	var song_duration = 0.0
	if OS.get_name() == "Android":
		song_duration = music_player.get_duration()
	else:
		song_duration = audio.stream.get_length()
	return clamp(song_duration,0x00000001,INF)

func is_paused() -> bool:
	if OS.get_name() == "Android":
		return music_player.is_paused()
	else:
		return !audio.playing

func set_playback_position(time:float) -> void:
	var was_paused:bool
	if OS.get_name() == "Android":
		if time <= music_player.get_duration():
			was_paused = music_player.is_paused()
			music_player.pause()
			music_player.seek(time)
			music_player.resume()
	else:
		if time <= audio.stream.get_length():
			was_paused = audio.stream_paused
			audio.stream_paused = false
			audio.seek(time)
			audio.stream_paused = was_paused

func pause(action:bool):
	if OS.get_name() == "Android":
		if action == true:
			music_player.pause()
		elif action == false:
			music_player.resume()
	else:
		audio.stream_paused = action

func play(song_name,dir_path) -> void:
	print("now playing: "+song_name)
	if OS.get_name() == "Android":
		var path = ProjectSettings.globalize_path(dir_path+"/audio.mp3")
		music_player.play(path)
		print(path)
	else:
		var file = FileAccess.open(dir_path+"\\audio.mp3", FileAccess.READ)
		var stream = AudioStreamMP3.new()
		stream.data = file.get_buffer(file.get_length())
		audio.stream = stream
		audio.play(0.0)
	
	playing_song_display.load_song(song_name,dir_path)
