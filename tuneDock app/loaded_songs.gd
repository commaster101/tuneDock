class_name SongManager extends Node
@export var audio_master:AudioMaster
@export var playlist_container:Node
@export var cur_index:int = 0
var plugin
var list_item_scene = preload("res://song_list_item.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await %Settings.loaded
	clear_playlist()
	load_all_songs()
	setup_playlist_select()
	if Engine.has_singleton("MusicPlayer"):
		plugin = Engine.get_singleton("MusicPlayer")
		plugin.connect("song_finished", _on_song_finished)
		
func _on_song_finished():
	print("Song ended! Queuing next...")
	play_next()

func play_prev():
	var next_index = cur_index-1
	if next_index < 0: next_index = playlist_container.get_child_count()-1
	play_item(playlist_container.get_child(next_index))

func play_next():
	var next_index = cur_index+1
	if next_index >= playlist_container.get_child_count(): next_index = 0
	play_item(playlist_container.get_child(next_index))

func play_item(item:song_list_item):
	cur_index = item.get_index()
	audio_master.play(item.text,item.dir_path)

func clear_playlist() -> void:
	for child in playlist_container.get_children():
		child.free()

func load_all_songs() -> void:
	var directories = DirAccess.get_directories_at(%Settings.songs_folder)
	for dir in directories:
		var new_list_item : song_list_item = list_item_scene.instantiate()
		new_list_item.text = dir
		new_list_item.dir_path = %Settings.songs_folder+"/"+dir
		new_list_item.audio_master = audio_master
		new_list_item.song_list_manager = self
		new_list_item.options_pressed.connect(options_pressed)
		playlist_container.add_child(new_list_item)
		print(dir)

func setup_playlist_select():
	$"select/playlist select".clear()
	for playlist in get_playlists():
		$"select/playlist select".add_item(playlist)

func get_playlists() -> Array[String]:
	var playlists = DirAccess.get_files_at(%Settings.playlist_folder)
	var out : Array[String] = ["all songs"]
	for playlist in playlists:
		if playlist.get_extension() == "cfg":
			out.append(playlist.trim_suffix(".cfg"))
	return out

func options_pressed(node:song_list_item):
	$"song options".load_song(node)
	print(node.text)

func _on_test_button_pressed() -> void:
	clear_playlist()
	load_all_songs()
