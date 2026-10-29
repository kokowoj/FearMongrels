extends Node

const SAVE_PATH = "user://settings.cfg"

# Audio settings
var master_volume: float = 0.8
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var muted: bool = false

# Display settings
var fullscreen: bool = false
var windowed_size: Vector2i = Vector2i(1280, 720)

# Gameplay and accessibility
var mouse_sensitivity: float = 1.0
var subtitles_enabled: bool = false


func _ready() -> void:
	var window = get_window()

	windowed_size = window.size
	fullscreen = (
		window.mode == Window.MODE_FULLSCREEN
		or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	)

	var has_saved_settings = load_settings()

	apply_audio()

	if has_saved_settings:
		apply_display()


func load_settings() -> bool:
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)

	if error == ERR_FILE_NOT_FOUND:
		return false

	if error != OK:
		push_warning("Could not load settings.")
		return false

	master_volume = clampf(
		float(config.get_value("audio", "master", master_volume)),
		0.0, 1.0
	)

	music_volume = clampf(
		float(config.get_value("audio", "music", music_volume)),
		0.0, 1.0
	)

	sfx_volume = clampf(
		float(config.get_value("audio", "sfx", sfx_volume)),
		0.0, 1.0
	)

	muted = bool(config.get_value("audio", "muted", muted))

	fullscreen = bool(
		config.get_value("display", "fullscreen", fullscreen)
	)

	var width = int(
		config.get_value("display", "width", windowed_size.x)
	)

	var height = int(
		config.get_value("display", "height", windowed_size.y)
	)

	windowed_size = Vector2i(
		maxi(width, 640),
		maxi(height, 360)
	)

	mouse_sensitivity = clampf(
		float(
			config.get_value(
				"gameplay",
				"sensitivity",
				mouse_sensitivity
			)
		),
		0.1, 2.0
	)

	subtitles_enabled = bool(
		config.get_value(
			"accessibility",
			"subtitles",
			subtitles_enabled
		)
	)

	return true


func save_settings() -> void:
	var config = ConfigFile.new()

	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "muted", muted)

	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "width", windowed_size.x)
	config.set_value("display", "height", windowed_size.y)

	config.set_value(
		"gameplay",
		"sensitivity",
		mouse_sensitivity
	)

	config.set_value(
		"accessibility",
		"subtitles",
		subtitles_enabled
	)

	var error = config.save(SAVE_PATH)

	if error != OK:
		push_error("Could not save settings.")


func apply_audio() -> void:
	_set_bus_volume("Master", master_volume, muted)
	_set_bus_volume("Music", music_volume, false)
	_set_bus_volume("SFX", sfx_volume, false)


func _set_bus_volume(
	bus_name: String,
	volume: float,
	force_mute: bool
) -> void:
	var index = AudioServer.get_bus_index(bus_name)

	if index == -1:
		push_warning("Missing audio bus: " + bus_name)
		return

	AudioServer.set_bus_volume_linear(
		index,
		maxf(volume, 0.001)
	)

	AudioServer.set_bus_mute(
		index,
		force_mute or volume <= 0.001
	)


func apply_display() -> void:
	var window = get_window()

	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		window.size = windowed_size
