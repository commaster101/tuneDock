class_name song_list_item extends PanelContainer
@export var cover_art_size:int
@export var cover_art:Texture
@export var text:String
@export_global_dir var dir_path := "/"
@export var audio_master:AudioMaster
@export var song_list_manager:SongManager
signal options_pressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HBoxContainer/Label.text = text 
	var img = Image.new()
	var error = img.load(dir_path+"\\cover.jpg")
	if error == OK:
		img.resize(cover_art_size, cover_art_size, Image.INTERPOLATE_LANCZOS)
		cover_art = ImageTexture.create_from_image(img)
		$HBoxContainer/cover_art.texture = cover_art

func _on_play_pressed() -> void:
	song_list_manager.play_item(self)


func _on_options_pressed() -> void:
	options_pressed.emit(self)
