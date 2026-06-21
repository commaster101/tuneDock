class_name global_settings extends Node
signal loaded
@export var songs_folder:String = "user://songs"
@export var playlist_folder:String = "user://playlists"

@export var last_domain:String = ""
@export var last_port:int

@export var background := 2

func _ready() -> void:
	if OS.get_name() == "Android":
		OS.request_permissions() # Triggers the native permission popup
	load_settings()
	playlist_folder = ProjectSettings.globalize_path(playlist_folder)

func load_settings():
	var config = ConfigFile.new()
	# Load the file from the user directory
	var error = config.load("user://settings.txt")
	# Check if the file opened successfully
	if error != OK:
		print("Failed to load config file. Error code: ", error)
		print("Default settings loaded")
		return
	
	songs_folder = config.get_value("storage","songs folder","user://songs")
	playlist_folder = config.get_value("storage","playlist folder","user://playlists")
	last_domain = config.get_value("routing","last domain","")
	last_port = config.get_value("routing","last port",5000)
	background = config.get_value("style","background",2)
	emit_signal("loaded")

func save_settings():
	var config = ConfigFile.new()
	config.set_value("storage","songs folder",songs_folder)
	config.set_value("storage","playlist folder",playlist_folder)
	
	config.set_value("routing","last domain",last_domain)
	config.set_value("routing","last port",last_port)
	
	config.set_value("style","background",background)
	
	config.save("user://settings.txt")
	print("settings saved")
