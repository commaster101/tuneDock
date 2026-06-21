@tool
extends EditorPlugin

var exportPlugin : AndroidExportPlugin

func _enable_plugin() -> void:
	pass

func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	exportPlugin = AndroidExportPlugin.new()
	add_export_plugin(exportPlugin)

func _exit_tree() -> void:
	remove_export_plugin(exportPlugin)
	exportPlugin = null

class AndroidExportPlugin extends EditorExportPlugin:
	var pluginName = "MusicPlayer"
	
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid: return true
		else: return false
	
	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug: #debug aar
			return PackedStringArray(["MusicPlayer/app-debug.aar"])
		else: #release aar
			return PackedStringArray(["MusicPlayer/app-debug.aar"])
	
	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug: #debug aar
			return PackedStringArray([])
		else: #release aar
			return PackedStringArray([])
	
	func _get_name() -> String:
		return pluginName
