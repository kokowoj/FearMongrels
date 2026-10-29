extends Control

@onready var start_button: Button = $StartButton
@onready var settings_button: Button = $SettingsButton
@onready var quit_button: Button = $QuitButton

@export var button_frame_png: Texture2D = preload("res://art/title/button.png")

const HOVER_GREEN = Color("#65DF7C")
const HOVER_SCALE = 1.07
const HOVER_SPEED = 0.15

const BUTTON_IMAGE_WIDTH = 0.80
const BUTTON_IMAGE_HEIGHT = 0.70

const GLOW_OPACITY = 0.90
const GLOW_BLUR_RADIUS = 12
const GLOW_PADDING_RATIO = 0.12

var hover_tweens: Dictionary = {}
var glow_nodes: Dictionary = {}

var artwork_texture: Texture2D
var glow_texture: Texture2D
var original_artwork_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	var label = $QuitGame.get_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if button_frame_png == null:
		push_error("Button image is missing!")
		return

	_prepare_button_textures()

	if artwork_texture == null or glow_texture == null:
		return

	for button in [start_button, settings_button, quit_button]:
		_setup_button(button)


func _prepare_button_textures() -> void:
	var image = button_frame_png.get_image()

	if image.is_compressed():
		image.decompress()

	image.convert(Image.FORMAT_RGBA8)

	var used_rect = image.get_used_rect()

	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		push_error("Button image has no visible pixels!")
		return

	var cropped = image.get_region(used_rect)

	original_artwork_size = Vector2(cropped.get_size())

	var padding = maxi(
		24,
		roundi(cropped.get_width() * GLOW_PADDING_RATIO)
	)

	var padded_width = cropped.get_width() + padding * 2
	var padded_height = cropped.get_height() + padding * 2

	var padded = Image.create_empty(
		padded_width,
		padded_height,
		false,
		Image.FORMAT_RGBA8
	)

	padded.fill(Color.TRANSPARENT)

	padded.blit_rect(
		cropped,
		Rect2i(Vector2i.ZERO, cropped.get_size()),
		Vector2i(padding, padding)
	)

	artwork_texture = ImageTexture.create_from_image(padded)

	var small = padded.duplicate()

	small.resize(
		maxi(1, roundi(padded_width * 0.20)),
		maxi(1, roundi(padded_height * 0.20)),
		Image.INTERPOLATE_BILINEAR
	)

	var blurred = _blur_alpha(small, GLOW_BLUR_RADIUS)

	blurred.resize(
		padded_width,
		padded_height,
		Image.INTERPOLATE_BILINEAR
	)

	glow_texture = ImageTexture.create_from_image(blurred)


func _blur_alpha(source: Image, radius: int) -> Image:
	var width = source.get_width()
	var height = source.get_height()

	var horizontal = Image.create_empty(
		width,
		height,
		false,
		Image.FORMAT_RGBA8
	)

	var vertical = Image.create_empty(
		width,
		height,
		false,
		Image.FORMAT_RGBA8
	)

	var sigma = float(radius) * 0.5
	var weights: Array[float] = []
	var weight_total = 0.0

	for offset in range(-radius, radius + 1):
		var weight = exp(
			-float(offset * offset) / (2.0 * sigma * sigma)
		)

		weights.append(weight)
		weight_total += weight

	for y in range(height):
		for x in range(width):
			var alpha = 0.0

			for offset in range(-radius, radius + 1):
				var sample_x = clampi(
					x + offset,
					0,
					width - 1
				)

				var weight = weights[offset + radius]

				alpha += source.get_pixel(
					sample_x,
					y
				).a * weight

			alpha /= weight_total

			horizontal.set_pixel(
				x,
				y,
				Color(1.0, 1.0, 1.0, alpha)
			)

	for y in range(height):
		for x in range(width):
			var alpha = 0.0

			for offset in range(-radius, radius + 1):
				var sample_y = clampi(
					y + offset,
					0,
					height - 1
				)

				var weight = weights[offset + radius]

				alpha += horizontal.get_pixel(
					x,
					sample_y
				).a * weight

			alpha /= weight_total

			vertical.set_pixel(
				x,
				y,
				Color(1.0, 1.0, 1.0, alpha)
			)

	return vertical


func _setup_button(button: Button) -> void:

	for state in [
		"normal",
		"hover",
		"pressed",
		"hover_pressed",
		"disabled",
        "focus"
	]:
		button.add_theme_stylebox_override(
			state,
			StyleBoxEmpty.new()
		)

	button.add_theme_color_override(
		"font_hover_color",
		HOVER_GREEN
	)

	button.add_theme_color_override(
		"font_hover_pressed_color",
		HOVER_GREEN
	)

	button.scale = Vector2.ONE
	button.pivot_offset = button.size / 2.0
	button.clip_contents = false

	var glow = TextureRect.new()
	glow.name = "SoftGreenGlow"
	glow.texture = glow_texture

	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE

	glow.show_behind_parent = true

	glow.modulate = Color(
		HOVER_GREEN.r,
		HOVER_GREEN.g,
		HOVER_GREEN.b,
		0.0
	)

	button.add_child(glow)

	glow_nodes[button] = glow

	var artwork = TextureRect.new()
	artwork.name = "ButtonArtwork"
	artwork.texture = artwork_texture

	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE

	artwork.show_behind_parent = true

	button.add_child(artwork)

	_position_button_layers(button, glow, artwork)

	button.resized.connect(
		_position_button_layers.bind(
			button,
			glow,
			artwork
		)
	)

	button.mouse_entered.connect(
		_on_button_hover.bind(button, true)
	)

	button.mouse_exited.connect(
		_on_button_hover.bind(button, false)
	)


func _position_button_layers(
	button: Button,
	glow: TextureRect,
	artwork: TextureRect
) -> void:
	if original_artwork_size.x <= 0:
		return

	var target_width = button.size.x * BUTTON_IMAGE_WIDTH
	var target_height = button.size.y * BUTTON_IMAGE_HEIGHT

	var scale_factor = minf(
		target_width / original_artwork_size.x,
		target_height / original_artwork_size.y
	)

	var final_size = Vector2(
		artwork_texture.get_size()
	) * scale_factor

	var final_position = (
		button.size - final_size
	) / 2.0

	glow.position = final_position
	glow.size = final_size

	artwork.position = final_position
	artwork.size = final_size

	button.pivot_offset = button.size / 2.0


func _on_button_hover(
	button: Button,
	hovered: bool
) -> void:
	if hover_tweens.has(button):
		var previous: Tween = hover_tweens[button]

		if previous.is_valid():
			previous.kill()

	var tween = create_tween()
	hover_tweens[button] = tween

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	var target_scale = Vector2.ONE

	if hovered:
		target_scale = Vector2(
			HOVER_SCALE,
			HOVER_SCALE
		)

	tween.tween_property(
		button,
		"scale",
		target_scale,
		HOVER_SPEED
	)

	if glow_nodes.has(button):
		var target_alpha = 0.0

		if hovered:
			target_alpha = GLOW_OPACITY

		tween.parallel().tween_property(
			glow_nodes[button],
			"modulate:a",
			target_alpha,
			HOVER_SPEED
		)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://player_select.tscn"
	)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://settings.tscn"
	)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://credits.tscn"
	)


func _on_quit_pressed() -> void:
	$QuitGame.popup_centered()


func _on_quit_game_confirmed() -> void:
	get_tree().quit()
