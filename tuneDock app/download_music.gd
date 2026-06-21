extends Control
@export var song_name_input : LineEdit
@export var artist_name_input : LineEdit
@export var domain_name_input : LineEdit
@export var port_number_input : LineEdit
@export var file_path_input : LineEdit
@export var song_file_dialog : FileDialog

@export var info_box : RichTextLabel

@onready var music_player = Engine.get_singleton("MusicPlayer") if Engine.has_singleton("MusicPlayer") else null

func _ready() -> void:
	await %Settings.loaded
	load_settings()

func load_settings():
	domain_name_input.text = %Settings.last_domain
	port_number_input.text = str(%Settings.last_port)
	file_path_input.text = %Settings.songs_folder

func update_settings():
	%Settings.last_domain = domain_name_input.text 
	%Settings.last_port = int(port_number_input.text)
	%Settings.songs_folder = file_path_input.text

func _on_download_song_pressed() -> void:
	var download = downloader.new()
	add_child(download)
	download.message.connect(received_download_message)
	download.download_song(
	song_name_input.text,
	artist_name_input.text,
	domain_name_input.text,
	int(port_number_input.text),
	file_path_input.text)

func received_download_message(message:String):
	info_box.append_text(message+"\n")

func _on_search_button_pressed() -> void:
	song_file_dialog.popup_centered()

func _on_file_dialog_dir_selected(dir: String) -> void:
	if OS.get_name() == "Android":
		if music_player:
			dir = music_player.resolve_content_uri(dir)
	file_path_input.text = ProjectSettings.globalize_path(dir)
	%Settings.songs_folder = ProjectSettings.globalize_path(dir)
	%Settings.save_settings()

func _on_save_settings_pressed() -> void:
	#TODO: check if data is valid
	update_settings()
	%Settings.save_settings()
