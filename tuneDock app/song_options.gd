extends Control
@export var cover_art:TextureRect
@export var song_name_edit:LineEdit
var current_song:song_list_item

func _ready() -> void:
	hide()

func load_song(song:song_list_item):
	current_song = song
	cover_art.texture = song.cover_art
	song_name_edit.text = song.text
	show()

func _on_cancel_pressed() -> void:
	hide()

func _on_delete_pressed() -> void:
	remove_song(current_song.dir_path)
	hide()
	
func remove_song(dir_path: String) -> void:
	if DirAccess.dir_exists_absolute(dir_path):
		DirAccess.remove_absolute(dir_path + "/cover.jpg")
		DirAccess.remove_absolute(dir_path + "/audio.mp3")
		DirAccess.remove_absolute(dir_path + "/lyrics.lrc")
		DirAccess.remove_absolute(dir_path + "/lyrics.txt")
		DirAccess.remove_absolute(dir_path)
