extends Control
@export var audio_master:AudioMaster
@export var cover_art:TextureRect
@export var song_name_label:Label
@export var lyrics_display:RichTextLabel

var lyrics_file = null
var lyrics = "[00:00.00] no lyrics"

func _ready() -> void:
	if OS.get_name() == "Android":
		lyrics_display

func _process(delta: float) -> void:
	update_lyrics_text()

func update_lyrics_text() -> void:
	var time = audio_master.get_playback_position()
	var out_lyrics := ""
	for line in lyrics.split("\n",true):
		var time_seconds = seconds_from_timecode(line.substr(0,10))
		var words = line.substr(10)
		if time_seconds <= time:
			words = "[b]"+words+"[/b]"
		out_lyrics += words
	lyrics_display.text = out_lyrics+"\n\n\n\n\n"
	#print(out_lyrics)

func seconds_from_timecode(timecode:String) -> float:
	#time code format [00:00.00]
	var split := timecode.split(":")
	if split.size() < 2: return 0.0
	split[0] = split[0].replace("[","")
	split[1] = split[1].replace("]","")
	return (int(split[0])*60)+int(split[1])

func load_song(song_name:String, dir_path:String) -> void:
	song_name_label.text = song_name
	
	var img = Image.new()
	var error = img.load(dir_path+"\\cover.jpg")
	if error == OK:
		img.resize(1000, 1000, Image.INTERPOLATE_LANCZOS)
		cover_art.texture = ImageTexture.create_from_image(img)
	
	lyrics_file = FileAccess.open(dir_path+"\\lyrics.lrc", FileAccess.READ)
	lyrics = "[00:00.00] failed to load lyrics (Before file read)"
	# Verify that the file successfully opened
	if lyrics_file:
		lyrics = lyrics_file.get_as_text()
		lyrics_file.close() # Always close the file stream when finished
	else:
		lyrics = str("[00:00.00] Failed to load lyrics. File not found.")
	lyrics_display.text = lyrics
