extends Node
@export var audio_master:AudioMaster

func _ready() -> void:
	if OS.get_name() == "Android":
		await get_tree().process_frame
		var rect := DisplayServer.get_display_safe_area()
		var window := DisplayServer.screen_get_size()
		var top_left = rect.position
		audio_master.offset_top = top_left.y/2.0
		audio_master.offset_bottom = ((rect.end.y+top_left.y)-window.y)
