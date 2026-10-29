extends Control

@onready var dagon_portrait: TextureButton = $DagonPortrait
@onready var dagon_splash: TextureRect = $DagonSplash
@onready var dagon_name: Label = $DagonName
@onready var confirm_button: Button = $ConfirmButton

@export var button_frame_png: Texture2D = preload(
	"res://art/title/button.png"
)

const HOVER_GREEN = Color("#65DF7C")
const HOVER_SCALE = 1.07
const HOVER_SPEED = 0.15

const BUTTON_GLOW_OPACITY = 0.90
const GLOW_BLUR_RADIUS = 12
const GLOW_PADDING_RATIO = 0.12

const BUTTON_IMAGE_WIDTH = 0.80
const BUTTON_IMAGE_HEIGHT = 0.70

const PORTRAIT_GLOW_OPACITY = 0.20

var dagon_selected: bool = false

var artwork_texture: Texture2D
var glow_texture: Texture2D
var original_artwork_size: Vector2 = Vector2.ZERO

var portrait_glow: TextureRect
var confirm_glow: TextureRect

var portrait_tween: Tween
var confirm_tween: Tween

var hover_sound: AudioStreamPlayer

var select_stream: AudioStream = preload(
	"res://audio/Menu Item Select.wav"
)

var hover_stream: AudioStream = preload(
	"res://audio/Menu Item Hover.wav"
)


func _ready() -> void:
	dagon_splash.hide()
	dagon_name.hide()

	dagon_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dagon_portrait.scale = Vector2.ONE
	dagon_portrait.pivot_offset = dagon_portrait.size / 2.0

	_prepare_button_textures()

	_setup_dagon_portrait()

	_setup_confirm_button()

	hover_sound = AudioStreamPlayer.new()
	add_child(hover_sound)

	hover_sound.stream = hover_stream

	if AudioServer.get_bus_index("SFX") != -1:
		hover_sound.bus = "SFX"

	dagon_portrait.mouse_entered.connect(
		_on_dagon_hovered
	)

	dagon_portrait.mouse_exited.connect(
		_on_dagon_unhovered
	)

	dagon_portrait.pressed.connect(
		_on_dagon_selected
	)

	confirm_button.mouse_entered.connect(
		_on_confirm_hovered
	)

	confirm_button.mouse_exited.connect(
		_on_confirm_unhovered
	)

	confirm_button.pressed.connect(
		_on_confirm_pressed
	)



func _prepare_button_textures() -> void:
	if button_frame_png == null:
		push_error("Button image is missing!")
		return

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

	var blurred = _blur_alpha(
		small,
		GLOW_BLUR_RADIUS
	)

	blurred.resize(
		padded_width,
		padded_height,
		Image.INTERPOLATE_BILINEAR
	)

	glow_texture = ImageTexture.create_from_image(blurred)



func _setup_confirm_button() -> void:
	if artwork_texture == null or glow_texture == null:
		return

	for state in [
		"normal",
		"hover",
		"pressed",
		"hover_pressed",
		"disabled",
		"focus"
	]:
		confirm_button.add_theme_stylebox_override(
			state,
			StyleBoxEmpty.new()
		)

	confirm_button.add_theme_color_override(
		"font_hover_color",
		HOVER_GREEN
	)

	confirm_button.add_theme_color_override(
		"font_hover_pressed_color",
		HOVER_GREEN
	)

	confirm_button.scale = Vector2.ONE
	confirm_button.pivot_offset = confirm_button.size / 2.0
	confirm_button.clip_contents = false
	confirm_button.icon = null

	confirm_glow = TextureRect.new()
	confirm_glow.name = "SoftGreenGlow"
	confirm_glow.texture = glow_texture

	confirm_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	confirm_glow.stretch_mode = TextureRect.STRETCH_SCALE
	confirm_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_glow.show_behind_parent = true

	confirm_glow.modulate = Color(
		HOVER_GREEN.r,
		HOVER_GREEN.g,
		HOVER_GREEN.b,
		0.0
	)

	confirm_button.add_child(confirm_glow)

	var artwork = TextureRect.new()
	artwork.name = "ButtonArtwork"
	artwork.texture = artwork_texture

	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.show_behind_parent = true

	confirm_button.add_child(artwork)

	_position_button_layers(
		confirm_button,
		confirm_glow,
		artwork
	)

	confirm_button.resized.connect(
		_position_button_layers.bind(
			confirm_button,
			confirm_glow,
			artwork
		)
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



func _setup_dagon_portrait() -> void:
	var portrait_texture = dagon_portrait.texture_normal

	if portrait_texture == null:
		return

	var image = portrait_texture.get_image()

	if image.is_compressed():
		image.decompress()

	image.convert(Image.FORMAT_RGBA8)

	var used_rect = image.get_used_rect()

	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return

	var cropped = image.get_region(used_rect)

	var padding = maxi(
		16,
		roundi(cropped.get_width() * 0.15)
	)

	var padded = Image.create_empty(
		cropped.get_width() + padding * 2,
		cropped.get_height() + padding * 2,
		false,
		Image.FORMAT_RGBA8
	)

	padded.fill(Color.TRANSPARENT)

	padded.blit_rect(
		cropped,
		Rect2i(Vector2i.ZERO, cropped.get_size()),
		Vector2i(padding, padding)
	)

	var small = padded.duplicate()

	small.resize(
		maxi(1, roundi(padded.get_width() * 0.20)),
		maxi(1, roundi(padded.get_height() * 0.20)),
		Image.INTERPOLATE_BILINEAR
	)

	var blurred = _blur_alpha(
		small,
		GLOW_BLUR_RADIUS
	)

	blurred.resize(
		padded.get_width(),
		padded.get_height(),
		Image.INTERPOLATE_BILINEAR
	)

	portrait_glow = TextureRect.new()
	portrait_glow.name = "SoftGreenGlow"

	portrait_glow.texture = ImageTexture.create_from_image(
		blurred
	)

	portrait_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_glow.stretch_mode = TextureRect.STRETCH_SCALE
	portrait_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_glow.show_behind_parent = true

	portrait_glow.modulate = Color(
		HOVER_GREEN.r,
		HOVER_GREEN.g,
		HOVER_GREEN.b,
		0.0
	)

	dagon_portrait.add_child(portrait_glow)

	_position_portrait_glow()

	dagon_portrait.resized.connect(
		_position_portrait_glow
	)


func _position_portrait_glow() -> void:
	if portrait_glow == null:
		return

	var padding = dagon_portrait.size * 0.12

	portrait_glow.position = -padding
	portrait_glow.size = dagon_portrait.size + padding * 2.0

	dagon_portrait.pivot_offset = dagon_portrait.size / 2.0



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



func _play_hover_sound() -> void:
	if hover_sound.stream != null:
		hover_sound.play()


func _play_select_sound() -> void:
	if select_stream == null:
		return

	var player = AudioStreamPlayer.new()

	get_tree().root.add_child(player)
	player.stream = select_stream

	if AudioServer.get_bus_index("SFX") != -1:
		player.bus = "SFX"

	player.finished.connect(player.queue_free)
	player.play()



func _animate_button(
	button: Control,
	glow: TextureRect,
	hovered: bool,
	selected: bool,
	opacity: float
) -> Tween:
	var tween = create_tween()

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

	if glow != null:
		var target_alpha = 0.0

		if hovered or selected:
			target_alpha = opacity

		tween.parallel().tween_property(
			glow,
			"modulate:a",
			target_alpha,
			HOVER_SPEED
		)

	return tween



func _on_dagon_hovered() -> void:
	_play_hover_sound()

	dagon_splash.show()

	if portrait_tween and portrait_tween.is_valid():
		portrait_tween.kill()

	portrait_tween = _animate_button(
		dagon_portrait,
		portrait_glow,
		true,
		dagon_selected,
		PORTRAIT_GLOW_OPACITY
	)


func _on_dagon_unhovered() -> void:
	if portrait_tween and portrait_tween.is_valid():
		portrait_tween.kill()
		
		dagon_splash.hide()

	portrait_tween = _animate_button(
		dagon_portrait,
		portrait_glow,
		false,
		dagon_selected,
		PORTRAIT_GLOW_OPACITY
	)


func _on_dagon_selected() -> void:
	dagon_selected = true

	_play_select_sound()

	dagon_name.show()
	dagon_splash.show()

	if portrait_glow != null:
		portrait_glow.modulate.a = PORTRAIT_GLOW_OPACITY



func _on_confirm_hovered() -> void:
	_play_hover_sound()

	if confirm_tween and confirm_tween.is_valid():
		confirm_tween.kill()

	confirm_tween = _animate_button(
		confirm_button,
		confirm_glow,
		true,
		false,
		BUTTON_GLOW_OPACITY
	)


func _on_confirm_unhovered() -> void:
	if confirm_tween and confirm_tween.is_valid():
		confirm_tween.kill()

	confirm_tween = _animate_button(
		confirm_button,
		confirm_glow,
		false,
		false,
		BUTTON_GLOW_OPACITY
	)


func _on_confirm_pressed() -> void:
	_play_select_sound()

	get_tree().change_scene_to_file(
		"res://dagon_testing.tscn"
	)
