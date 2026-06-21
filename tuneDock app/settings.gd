extends Control
@export_category("save location")
@export var song_file_dialog : FileDialog
@export var song_file_input : LineEdit
@export_category("background")
@export var background_rect : TextureRect
@export var background_materials : Array[Material]
@export var cur_background : int

func _ready() -> void:
	await %Settings.loaded
	_on_background_select_item_selected(%Settings.background)
	$"VBoxContainer/background select".selected = cur_background
	$"VBoxContainer/songs save location/file path input".text = %Settings.songs_folder

func _on_search_button_pressed() -> void:
	song_file_dialog.popup_centered()


func _on_songs_path_dialog_dir_selected(dir: String) -> void:
	song_file_input.text = dir


func _on_background_select_item_selected(index: int) -> void:
	background_rect.material = background_materials[index]
	cur_background = index


func _on_save_settings_pressed() -> void:
	update_settings()
	%Settings.save_settings()

func update_settings():
	%Settings.songs_folder = $"VBoxContainer/songs save location/file path input".text
	%Settings.background = cur_background
