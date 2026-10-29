extends Control

var settings_store: Node
var display_option: OptionButton
var resolution_option: OptionButton

var changing_scene: bool = false

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]


func _ready() -> void:
	_setup_navigation()

	settings_store = get_node_or_null("/root/GameSettings")

	if settings_store == null:
		push_error("GameSettings Autoload is missing.")
		return

	_setup_audio()
	_setup_display()
	_setup_gameplay()



func _setup_navigation() -> void:
	var back_button = find_child(
		"BackButton", true, false
	) as BaseButton

	if back_button != null:
		back_button.disabled = false

		if not back_button.pressed.is_connected(
			_on_back_button_pressed
		):
			back_button.pressed.connect(
				_on_back_button_pressed
			)

	var credits_button = find_child(
		"CreditsButton", true, false
	) as BaseButton

	if credits_button != null:
		credits_button.disabled = false

		if not credits_button.pressed.is_connected(
			_on_credits_button_pressed
		):
			credits_button.pressed.connect(
				_on_credits_button_pressed
			)


func _on_back_button_pressed() -> void:
	if changing_scene:
		return

	changing_scene = true
	_save_settings()

	get_tree().change_scene_to_file(
        "res://main_menu.tscn"
	)


func _on_credits_button_pressed() -> void:
	if changing_scene:
		return

	changing_scene = true
	_save_settings()

	get_tree().change_scene_to_file(
        "res://credits.tscn"
	)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()



func _setup_slider(
	node_name: String,
	minimum: float,
	maximum: float,
	increment: float,
	saved_value: float,
	callback: Callable
) -> void:
	var slider = find_child(
		node_name, true, false
	) as Range

	if slider == null:
		push_warning("Slider missing: " + node_name)
		return

	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.page = 0.0
	slider.set_value_no_signal(saved_value)

	if not slider.value_changed.is_connected(callback):
		slider.value_changed.connect(callback)



func _setup_checkbox(
	node_name: String,
	saved_value: bool,
	callback: Callable
) -> void:
	var checkbox = find_child(
		node_name, true, false
	) as BaseButton

	if checkbox == null:
		push_warning("Checkbox missing: " + node_name)
		return

	checkbox.toggle_mode = true
	checkbox.set_pressed_no_signal(saved_value)

	if not checkbox.toggled.is_connected(callback):
		checkbox.toggled.connect(callback)



func _setup_audio() -> void:
	_setup_slider(
		"MasterVolumeSlider",
		0.0, 100.0, 1.0,
		float(settings_store.get("master_volume")) * 100.0,
		_on_master_changed
	)

	_setup_slider(
		"MusicVolumeSlider",
		0.0, 100.0, 1.0,
		float(settings_store.get("music_volume")) * 100.0,
		_on_music_changed
	)

	_setup_slider(
		"SFXVolumeSlider",
		0.0, 100.0, 1.0,
		float(settings_store.get("sfx_volume")) * 100.0,
		_on_sfx_changed
	)

	_setup_checkbox(
		"MuteCheckBox",
		bool(settings_store.get("muted")),
		_on_mute_changed
	)


func _on_master_changed(value: float) -> void:
	_update_audio("master_volume", value / 100.0)


func _on_music_changed(value: float) -> void:
	_update_audio("music_volume", value / 100.0)


func _on_sfx_changed(value: float) -> void:
	_update_audio("sfx_volume", value / 100.0)


func _on_mute_changed(enabled: bool) -> void:
	_update_audio("muted", enabled)


func _update_audio(
	setting_name: String,
	value: Variant
) -> void:
	if settings_store == null:
		return

	settings_store.set(setting_name, value)
	settings_store.call("apply_audio")
	_save_settings()



func _setup_display() -> void:
	display_option = find_child(
		"DisplayModeOption", true, false
	) as OptionButton

	resolution_option = find_child(
		"ResolutionOption", true, false
	) as OptionButton

	if display_option == null:
		push_error("DisplayModeOption not found.")
		return

	if resolution_option == null:
		push_error("ResolutionOption not found.")
		return

	display_option.clear()
	display_option.add_item("Windowed")
	display_option.add_item("Fullscreen")

	display_option.fit_to_longest_item = true
	display_option.disabled = false

	var fullscreen_enabled = bool(
		settings_store.get("fullscreen")
	)

	display_option.select(
		1 if fullscreen_enabled else 0
	)

	resolution_option.clear()
	resolution_option.fit_to_longest_item = true

	var saved_size: Vector2i = settings_store.get(
        "windowed_size"
	)

	var choices: Array[Vector2i] = []

	for size in RESOLUTIONS:
		choices.append(size)

	if not choices.has(saved_size):
		choices.append(saved_size)

	for size in choices:
		var index = resolution_option.item_count

		resolution_option.add_item(
			"%d x %d" % [size.x, size.y]
		)

		resolution_option.set_item_metadata(
			index, size
		)

		if size == saved_size:
			resolution_option.select(index)

  
	resolution_option.disabled = false

	if not display_option.item_selected.is_connected(
		_on_display_changed
	):
		display_option.item_selected.connect(
			_on_display_changed
		)

	if not resolution_option.item_selected.is_connected(
		_on_resolution_changed
	):
		resolution_option.item_selected.connect(
			_on_resolution_changed
		)


func _on_display_changed(index: int) -> void:
	if settings_store == null:
		return

	var fullscreen_enabled = (index == 1)

	settings_store.set(
		"fullscreen", fullscreen_enabled
	)

	resolution_option.disabled = false

	_save_settings()

	call_deferred("_apply_display_change")


func _apply_display_change() -> void:
	if not is_inside_tree():
		return

	settings_store.call("apply_display")

	if not bool(settings_store.get("fullscreen")):
		await get_tree().process_frame

		if not is_inside_tree():
			return

		var saved_size: Vector2i = settings_store.get(
            "windowed_size"
		)

		var window = get_window()
		window.size = saved_size
		window.move_to_center()


func _on_resolution_changed(index: int) -> void:
	if settings_store == null:
		return

	var selected_size: Vector2i = (
		resolution_option.get_item_metadata(index)
	)

	settings_store.set(
		"windowed_size", selected_size
	)

	_save_settings()

	# Resize only if currently windowed
	if not bool(settings_store.get("fullscreen")):
		call_deferred("_apply_resolution_change")


func _apply_resolution_change() -> void:
	if not is_inside_tree():
		return

	await get_tree().process_frame

	if not is_inside_tree():
		return

	var saved_size: Vector2i = settings_store.get(
        "windowed_size"
	)

	var window = get_window()
	window.size = saved_size
	window.move_to_center()


func _setup_gameplay() -> void:
	_setup_slider(
		"SensitivitySlider",
		0.1, 2.0, 0.1,
		float(settings_store.get("mouse_sensitivity")),
		_on_sensitivity_changed
	)

	_setup_checkbox(
		"SubtitlesCheckBox",
		bool(settings_store.get("subtitles_enabled")),
		_on_subtitles_changed
	)


func _on_sensitivity_changed(value: float) -> void:
	if settings_store == null:
		return

	settings_store.set(
		"mouse_sensitivity", value
	)

	_save_settings()


func _on_subtitles_changed(enabled: bool) -> void:
	if settings_store == null:
		return

	settings_store.set(
		"subtitles_enabled", enabled
	)

	_save_settings()

func _save_settings() -> void:
	if settings_store != null:
		settings_store.call("save_settings")
