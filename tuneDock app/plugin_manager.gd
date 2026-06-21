class_name PluginManager extends Node
@export var download_music:Control
var music_plugin
signal plugin_loaded
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() != "Android": return
	OS.request_permissions()
	get_tree().auto_accept_quit = false
	get_tree().paused = false
	await $Timer.timeout
	if Engine.has_singleton("MusicPlayer"):
		music_plugin = Engine.get_singleton("MusicPlayer")
		music_plugin.helloWorld()
		plugin_loaded.emit()
		print(await get_music_dir())
	else: download_music.received_download_message("Android audio plugin failed to load ):")

func get_music_dir():
	if OS.get_name() != "Android": return
	if !music_plugin: await plugin_loaded
	return music_plugin.get_music_dir()

func _notification(what):
	pass
