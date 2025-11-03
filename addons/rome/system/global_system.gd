extends Node

## 音频总线定义
class AudioBuses:
	const master:= &"Master"
	const sfx	:= &"SFX"
	const music	:= &"Music"

## 音频配置
class AudioConfig:
	const MUSIC_FOLDER = "res://Assets/Audio/Music"
	const SUPPORTED_EXTENSIONS = ["mp3", "wav", "ogg"]

	## 默认音量设置
	static var master_volume: float = 1.0
	static var music_volume: float = 0.8
	static var sfx_volume: float = 1.0

	## 音乐设置
	static var shuffle_music: bool = true
	static var auto_play_music: bool = false

	## 音效设置
	static var max_sound_instances: int = 16
	static var use_sound_pool: bool = true

	## 从 SaveManager 加载配置
	static func load_config() -> void:
		if Engine.has_singleton("SaveManager"):
			var save_manager = Engine.get_singleton("SaveManager")
			master_volume = save_manager.load_config("Audio", "master_volume", 1.0)
			music_volume = save_manager.load_config("Audio", "music_volume", 0.8)
			sfx_volume = save_manager.load_config("Audio", "sfx_volume", 1.0)
			shuffle_music = save_manager.load_config("Audio", "shuffle_music", true)
			auto_play_music = save_manager.load_config("Audio", "auto_play_music", false)
			max_sound_instances = save_manager.load_config("Audio", "max_sound_instances", 16)
			use_sound_pool = save_manager.load_config("Audio", "use_sound_pool", true)

	## 保存配置到 SaveManager
	static func save_config() -> void:
		if Engine.has_singleton("SaveManager"):
			var save_manager = Engine.get_singleton("SaveManager")
			save_manager.save_config("Audio", "master_volume", master_volume)
			save_manager.save_config("Audio", "music_volume", music_volume)
			save_manager.save_config("Audio", "sfx_volume", sfx_volume)
			save_manager.save_config("Audio", "shuffle_music", shuffle_music)
			save_manager.save_config("Audio", "auto_play_music", auto_play_music)
			save_manager.save_config("Audio", "max_sound_instances", max_sound_instances)
			save_manager.save_config("Audio", "use_sound_pool", use_sound_pool)

	## 设置主音量
	static func set_master_volume(volume: float) -> void:
		master_volume = clamp(volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioBuses.master), linear_to_db(master_volume))
		save_config()

	## 设置音乐音量
	static func set_music_volume(volume: float) -> void:
		music_volume = clamp(volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioBuses.music), linear_to_db(music_volume))
		save_config()

	## 设置音效音量
	static func set_sfx_volume(volume: float) -> void:
		sfx_volume = clamp(volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(AudioBuses.sfx), linear_to_db(sfx_volume))
		save_config()
