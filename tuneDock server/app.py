from flask import Flask, request, jsonify, send_from_directory, abort, url_for
import yt_dlp
import requests
import re
from pathlib import Path

app = Flask(__name__)

DOWNLOAD_DIR = Path("downloads")
DOWNLOAD_DIR.mkdir(exist_ok=True)

def normalize_string(s):
    s = s.strip()
    s = re.sub(r'\s+', ' ', s)
    s = s.lower()
    return safe_filename(s)

def safe_filename(name):
    return re.sub(r'[<>:"/\\|?*]', '_', name)


def get_song_folder(song_name, artist):
    folder_name = (
        f"{safe_filename(song_name)} - "
        f"{safe_filename(artist)}"
    )

    folder = DOWNLOAD_DIR / folder_name
    folder.mkdir(parents=True, exist_ok=True)

    return folder


def download_song(song_name, artist):
    song_folder = get_song_folder(song_name, artist)
    audio_path = song_folder / "audio.mp3"

    search_query = f"{song_name} {artist}"
    ydl_opts = {
        "ffmpeg_location": r"C:\Users\User\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.WinGet.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe",

        "format": "bestaudio/best",

        "outtmpl": str(
            song_folder / "audio.%(ext)s"
        ),

        "quiet": False,
        "no_warnings": False,

        "postprocessors": [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "mp3",
            "preferredquality": "192"
        }]
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.extract_info(
            f"ytsearch:{search_query}",
            download=True
        )
    return str(audio_path)

def download_cover(song_name, artist):
    song_folder = get_song_folder(song_name, artist)
    cover_path = song_folder / "cover.jpg"

    # Cover Art Archive
    try:
        mb = requests.get(
            "https://musicbrainz.org/ws/2/recording/",
            params={
                "query": f'recording:"{song_name}" AND artist:"{artist}"',
                "fmt": "json",
                "limit": 1
            },
            headers={
                "User-Agent": "MusicDownloader/1.0"
            },
            timeout=10
        )

        mb.raise_for_status()

        recordings = mb.json().get("recordings", [])

        if recordings:
            releases = recordings[0].get("releases", [])

            if releases:
                release_id = releases[0]["id"]

                cover_url = (
                    f"https://coverartarchive.org/release/"
                    f"{release_id}/front-1200"
                )

                img = requests.get(
                    cover_url,
                    allow_redirects=True,
                    timeout=15
                )

                if img.status_code == 200:
                    cover_path.write_bytes(img.content)
                    return str(cover_path)

    except Exception as e:
        print("Cover Art Archive error:", e)

    # iTunes fallback
    try:
        r = requests.get(
            "https://itunes.apple.com/search",
            params={
                "term": f"{artist} {song_name}",
                "entity": "song",
                "limit": 1
            },
            timeout=10
        )

        r.raise_for_status()

        data = r.json()

        if data.get("resultCount", 0) > 0:
            artwork_url = data["results"][0]["artworkUrl100"]

            artwork_url = (
                artwork_url
                .replace("100x100bb", "1200x1200bb")
                .replace("100x100", "1200x1200")
            )

            img = requests.get(
                artwork_url,
                timeout=15
            )

            if img.status_code == 200:
                cover_path.write_bytes(img.content)
                return str(cover_path)

    except Exception as e:
        print("iTunes error:", e)

    return None


def download_lyrics(song_name, artist):
    song_folder = get_song_folder(song_name, artist)

    lyrics_txt_path = song_folder / "lyrics.txt"
    lyrics_lrc_path = song_folder / "lyrics.lrc"

    try:
        r = requests.get(
            "https://lrclib.net/api/search",
            params={
                "track_name": song_name,
                "artist_name": artist
            },
            headers={
                "User-Agent": "MusicDownloader/1.0"
            },
            timeout=10
        )

        r.raise_for_status()

        results = r.json()

        if not results:
            return {
                "txt": None,
                "lrc": None
            }

        song = results[0]

        plain_lyrics = song.get("plainLyrics")
        synced_lyrics = song.get("syncedLyrics")

        if plain_lyrics:
            lyrics_txt_path.write_text(
                plain_lyrics,
                encoding="utf-8"
            )

        if synced_lyrics:
            lyrics_lrc_path.write_text(
                synced_lyrics,
                encoding="utf-8"
            )

        return {
            "txt": str(lyrics_txt_path) if plain_lyrics else None,
            "lrc": str(lyrics_lrc_path) if synced_lyrics else None
        }

    except Exception as e:
        print("Lyrics download error:", e)

        return {
            "txt": None,
            "lrc": None
        }


@app.route("/")
def index():
    return jsonify({
        "service": "Music Downloader API",
        "status": "online"
    })


@app.route("/cache", methods=["GET"])
def cache_song():
    try:
        song_name = request.args.get("song_name")
        artist = request.args.get("artist")

        if not song_name or not artist:
            return jsonify({
                "success": False,
                "error": "Missing song_name or artist"
            }), 400

        song_name = normalize_string(song_name)
        artist = normalize_string(artist)

        song_folder = get_song_folder(
            song_name,
            artist
        )

        audio_file = song_folder / "audio.mp3"
        cover_file = song_folder / "cover.jpg"
        lyrics_txt = song_folder / "lyrics.txt"
        lyrics_lrc = song_folder / "lyrics.lrc"

        # Skip download if already exists
        if not audio_file.exists():
            audio_path = download_song(
                song_name,
                artist
            )
        if not cover_file.exists():
            cover_path = download_cover(
                song_name,
                artist
            )
        if not lyrics_txt.exists() and not lyrics_lrc.exists():
            lyrics = download_lyrics(
                song_name,
                artist
            )

        base_url = request.host_url.rstrip("/") + "/files"

        if (song_folder / "audio.mp3").exists():
            audio_url = url_for(
                "serve_file",
                filename=f"{song_folder.name}/audio.mp3",
                _external=True
        ) 
        else: audio_url = None
        if (song_folder / "cover.jpg").exists():
            cover_url = url_for(
                "serve_file",
                filename=f"{song_folder.name}/cover.jpg",
                _external=True
        )
        else: cover_url = None
        if (song_folder / "lyrics.txt").exists():
            lyrics_txt_url = url_for(
                "serve_file",
                filename=f"{song_folder.name}/lyrics.txt",
                _external=True
        )
        else: lyrics_txt_url = None
        if (song_folder / "lyrics.lrc").exists():
            lyrics_lrc_url = url_for(
                "serve_file",
                filename=f"{song_folder.name}/lyrics.lrc",
                _external=True
        )
        else: lyrics_lrc_url = None
        
        return jsonify({
            "success": True,
            "song_name": song_name,
            "artist": artist,
            "audio_url": audio_url,
            "cover_url": cover_url,
            "lyrics_txt_url": lyrics_txt_url,
            "lyrics_lrc_url": lyrics_lrc_url
        })

    except Exception as e:
        print("ERROR:", e)

        return jsonify({
            "success": False,
            "error": str(e)
        }), 500


@app.route("/song", methods=["GET"])
def get_song():
    song_name = request.args.get("song_name")
    artist = request.args.get("artist")

    if not song_name or not artist:
        return jsonify({
            "success": False,
            "error": "Missing song_name or artist"
        }), 400

    song_folder = get_song_folder(
        song_name,
        artist
    )

    audio_file = song_folder / "audio.mp3"
    cover_file = song_folder / "cover.jpg"
    lyrics_txt = song_folder / "lyrics.txt"
    lyrics_lrc = song_folder / "lyrics.lrc"

    if not any([
        audio_file.exists(),
        cover_file.exists(),
        lyrics_txt.exists(),
        lyrics_lrc.exists()
    ]):
        return jsonify({
            "success": False,
            "error": "Song not downloaded"
        }), 404

    base_url = request.host_url.rstrip("/") + "/files"

    return jsonify({
        "success": True,
        "song_name": song_name,
        "artist": artist,

        "audio_url":
            f"{base_url}/{song_folder.name}/audio.mp3"
            if audio_file.exists() else None,

        "cover_url":
            f"{base_url}/{song_folder.name}/cover.jpg"
            if cover_file.exists() else None,

        "lyrics_txt_url":
            f"{base_url}/{song_folder.name}/lyrics.txt"
            if lyrics_txt.exists() else None,

        "lyrics_lrc_url":
            f"{base_url}/{song_folder.name}/lyrics.lrc"
            if lyrics_lrc.exists() else None
    })


@app.route("/files/<path:filename>")
def serve_file(filename):
    file_path = DOWNLOAD_DIR / filename

    if not file_path.exists():
        abort(404)

    return send_from_directory(
        DOWNLOAD_DIR,
        filename,
        as_attachment=False
    )

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )