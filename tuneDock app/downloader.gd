class_name downloader extends Node

signal message(message_out:String)

func download_song(song_name: String, artist: String, domain: String, port: int,save_path: String = %Settings.songs_folder):
	message.emit(
	"Requesting URLs for %s by %s from %s on port %d" % [
		song_name,
		artist,
		domain,
		port])
	
	var json : Dictionary = await request_song_cache(song_name ,artist ,domain ,port)
	if json.is_empty(): return
	print(json)
	
	#message.emit(str(json))
	var save_location : String = save_path+"/"+song_name+" - "+artist
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_location))
	if json.get("audio_url") == null:
		message.emit("Can't find audio!")
		message.emit("Cancelling download ):")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_location))
		return
	else:
		message.emit("Downloading audio")
		download_from_url(json.get("audio_url"),save_location+"/audio.mp3")

	if json.get("cover_url") == null: message.emit("Can't find cover art!")
	else:
		message.emit("Downloading cover")
		download_from_url(json.get("cover_url"),save_location+"/cover.jpg")

	if json.get("lyrics_lrc_url") == null: message.emit("Can't find synced lyrics!")
	else:
		message.emit("Downloading synced lyrics")
		download_from_url(json.get("lyrics_lrc_url"),save_location+"/lyrics.lrc")
	
	if json.get("lyrics_txt_url") == null: message.emit("Can't find plain lyrics!")
	else:
		message.emit("Downloading plain text lyrics")
		download_from_url(json.get("lyrics_txt_url"),save_location+"/lyrics.txt")
	message.emit("Download complete")

func download_from_url(url: String, save_path: String) -> bool:
	var http := HTTPRequest.new()
	add_child(http)

	http.download_file = save_path

	var err := http.request(url)

	if err != OK:
		print("error downloading "+url+":"+str(err))
		message.emit("error downloading "+url+":"+str(err))
		return false

	var result = await http.request_completed
	print(result[1])
	return result[1] == 200

func request_song_cache(song_name: String, artist: String,domain:String,port:int) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)

	var query := (
		"http://" + domain +":"+ str(port) + "/cache?"
		+ "song_name=" + song_name.uri_encode()
		+ "&artist=" + artist.uri_encode()
	)

	var err := http.request(query)

	if err != OK:
		push_error("Failed to start url request:"+str(err))
		message.emit("Failed to start url request:"+str(err))
		return {}

	var result = await http.request_completed

	var response_code: int = result[1]
	var body: PackedByteArray = result[3]

	if response_code != 200:
		push_error("Error server returned " + str(response_code))
		message.emit("Error server returned " + str(response_code))
		return {}

	var json := JSON.new()

	if json.parse(body.get_string_from_utf8()) != OK:
		push_error("Error invalid JSON")
		message.emit("Error invalid JSON")
		return {}

	return json.data
