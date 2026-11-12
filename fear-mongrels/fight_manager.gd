
extends Node2D

# Blue/Green Dagon = Player 1
@onready var player_1 = $TempPlayer2

# Red/Brown Dagon = Player 2
@onready var player_2 = $Dagon

# Existing HUD elements
@onready var player_1_health_bar: ProgressBar = \
	$FightUI/HUD/Player1Health

@onready var player_2_health_bar: ProgressBar = \
	$FightUI/HUD/Player2Health

@onready var timer_label: Label = \
	$FightUI/HUD/RoundTimer

@onready var status_label: Label = \
	$FightUI/HUD/StatusLabel

# Announcement elements
@onready var announcement: AnimatedSprite2D = \
	$FightUI/Announcement

@onready var announcement_background: ColorRect = \
	$FightUI/AnnouncementBackground


# Match settings
const ROUND_DURATION: float = 99.0
const WINS_NEEDED: int = 2

var round_time: float = ROUND_DURATION
var round_number: int = 1

var player_1_wins: int = 0
var player_2_wins: int = 0

var round_active: bool = false
var match_over: bool = false

# Original character positions
var player_1_start: Vector2
var player_2_start: Vector2

# Original facing directions
var player_1_flip: bool
var player_2_flip: bool


func _ready() -> void:
	# Remember starting positions.
	player_1_start = player_1.global_position
	player_2_start = player_2.global_position

	player_1_flip = player_1.get_node(
		"AnimatedSprite2D"
	).flip_h

	player_2_flip = player_2.get_node(
		"AnimatedSprite2D"
	).flip_h

	# Configure health bars.
	player_1_health_bar.max_value = player_1.max_health
	player_2_health_bar.max_value = player_2.max_health

	player_1_health_bar.value = player_1.health
	player_2_health_bar.value = player_2.health

	# Connect health signals.
	player_1.health_changed.connect(
		_on_player_1_health_changed
	)

	player_2.health_changed.connect(
		_on_player_2_health_changed
	)

	# Connect knockout signals.
	player_1.defeated.connect(
		_on_player_1_defeated
	)

	player_2.defeated.connect(
		_on_player_2_defeated
	)

	# Hide announcements initially.
	announcement.visible = false
	announcement_background.visible = false
	status_label.visible = false

	_update_timer_display()

	# Start the first round.
	await _start_round()


func _process(delta: float) -> void:
	if not round_active or match_over:
		return

	round_time = maxf(round_time - delta, 0.0)
	_update_timer_display()

	if round_time <= 0.0:
		_handle_timeout()


func _update_timer_display() -> void:
	timer_label.text = str(ceili(round_time))


func _set_fighters_enabled(enabled: bool) -> void:
	player_1.set_physics_process(enabled)
	player_2.set_physics_process(enabled)


func _reset_fighters() -> void:
	# Return fighters to starting positions.
	player_1.global_position = player_1_start
	player_2.global_position = player_2_start

	# Restore health and animations.
	player_1.reset_health()
	player_2.reset_health()

	# Restore original facing directions.
	player_1.get_node(
		"AnimatedSprite2D"
	).flip_h = player_1_flip

	player_2.get_node(
		"AnimatedSprite2D"
	).flip_h = player_2_flip


func _start_round() -> void:
	round_active = false
	_set_fighters_enabled(false)

	_reset_fighters()

	round_time = ROUND_DURATION
	_update_timer_display()

	status_label.text = "ROUND " + str(round_number)
	status_label.visible = true

	# Show the fullscreen starting announcement.
	await _play_announcement("game_start")

	status_label.visible = false

	# Begin fighting.
	_set_fighters_enabled(true)
	round_active = true

	print("Round ", round_number, " started!")


func _play_announcement(animation_name: String) -> void:
	# Prepare the animation.
	announcement.animation = animation_name
	announcement.frame = 0

	# Get screen dimensions.
	var screen_size: Vector2 = get_viewport_rect().size

	# Make the black background fill the screen.
	announcement_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Get the size of an announcement frame.
	var sprite_frames: SpriteFrames = announcement.sprite_frames
	var frame_texture: Texture2D = sprite_frames.get_frame_texture(
		animation_name, 0
	)

	if frame_texture == null:
		push_error(
			"Missing announcement frames: " + animation_name
		)
		return

	var frame_size: Vector2 = frame_texture.get_size()

	# Scale proportionally to fit within the screen.
	var scale_factor: float = minf(
		screen_size.x / frame_size.x,
		screen_size.y / frame_size.y
	)

	announcement.scale = Vector2.ONE * scale_factor

	# Center the animation.
	announcement.centered = true
	announcement.position = screen_size / 2.0

	# Cover the arena with black.
	announcement_background.visible = true

	# Display the announcement.
	announcement.visible = true
	announcement.play(animation_name)

	await announcement.animation_finished

	# Reveal the fighting arena again.
	announcement.visible = false
	announcement_background.visible = false


func _on_player_1_health_changed(new_health: int) -> void:
	player_1_health_bar.value = new_health


func _on_player_2_health_changed(new_health: int) -> void:
	player_2_health_bar.value = new_health


func _on_player_1_defeated() -> void:
	if not round_active:
		return

	# Player 2 wins the round.
	_finish_round(2)


func _on_player_2_defeated() -> void:
	if not round_active:
		return

	# Player 1 wins the round.
	_finish_round(1)


func _handle_timeout() -> void:
	if not round_active:
		return

	if player_1.health > player_2.health:
		_finish_round(1)

	elif player_2.health > player_1.health:
		_finish_round(2)

	else:
		# Replay a tied round.
		_finish_round(0)


func _finish_round(winner: int) -> void:
	if not round_active:
		return

	round_active = false
	_set_fighters_enabled(false)

	call_deferred("_resolve_round", winner)


func _resolve_round(winner: int) -> void:
	if winner == 1:
		player_1_wins += 1
		status_label.text = "PLAYER 1 WINS ROUND!"

	elif winner == 2:
		player_2_wins += 1
		status_label.text = "PLAYER 2 WINS ROUND!"

	else:
		status_label.text = "DRAW! REPLAY ROUND!"

	status_label.visible = true

	# Fullscreen round announcement.
	await _play_announcement("round_finish")

	# Check for match victory.
	if player_1_wins >= WINS_NEEDED:
		await _finish_match(1)
		return

	if player_2_wins >= WINS_NEEDED:
		await _finish_match(2)
		return

	# Continue to the next round.
	if winner != 0:
		round_number += 1

	await _start_round()


func _finish_match(winner: int) -> void:
	match_over = true
	round_active = false

	_set_fighters_enabled(false)

	# Fullscreen game finish announcement.
	await _play_announcement("game_finish")

	if winner == 1:
		status_label.text = \
			"PLAYER 1 WINS! PRESS R TO RESTART"
	else:
		status_label.text = \
			"PLAYER 2 WINS! PRESS R TO RESTART"

	status_label.visible = true

	print("GAME FINISH! Player ", winner, " wins!")


func _input(event: InputEvent) -> void:
	if not match_over:
		return

	# Restart the match with R.
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				get_tree().reload_current_scene()
