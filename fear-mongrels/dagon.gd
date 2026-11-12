extends CharacterBody2D

signal health_changed(new_health: int)
signal defeated

@export var speed: float = 200.0
@export var jump_velocity: float = -550.0

# Keep Red Dagon's working sprite positions
@export var idle_position_y: float = -240.0
@export var walk_position_y: float = -240.0

# Combat settings
@export var max_health: int = 1000
@export var punch_damage: int = 75
@export var kick_damage: int = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

# Attack sound files
const PUNCH_SOUND: AudioStream = preload(
	"res://audio/Dagon - Light Punch-2.wav"
)

const KICK_SOUND: AudioStream = preload(
	"res://audio/Dagon - Light Kick-2.wav"
)

var attack_sound: AudioStreamPlayer

var gravity: float = 980.0
var is_attacking: bool = false
var health: int = 1000

var current_attack_damage: int = 0
var attack_has_hit: bool = false
var hitbox_distance: float = 100.0


func _ready() -> void:
	health = max_health
	hitbox_distance = absf(hitbox.position.x)

	# Create audio player for attacks
	attack_sound = AudioStreamPlayer.new()
	attack_sound.name = "AttackSound"
	add_child(attack_sound)

	if AudioServer.get_bus_index("SFX") != -1:
		attack_sound.bus = "SFX"

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)

	_update_sprite_position()
	_update_hitbox_direction()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Stop player controls when health reaches zero
	if health <= 0:
		velocity.x = 0.0
		is_attacking = false
		change_animation("idle")
		_update_sprite_position()
		move_and_slide()
		return

	# Player 2 movement
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	# Face the movement direction
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	_update_hitbox_direction()

	# Jump
	if Input.is_action_just_pressed("ui_accept") \
	and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# Punch
	if Input.is_action_just_pressed("punch") \
	and not is_attacking:
		_start_attack("light_punch", punch_damage)

	# Kick
	elif Input.is_action_just_pressed("kick") \
	and not is_attacking:
		_start_attack("light_kick", kick_damage)

	# Normal movement animations
	if not is_attacking:
		if not is_on_floor():
			change_animation("jump")
		elif direction != 0:
			change_animation("walk")
		else:
			change_animation("idle")

	_update_sprite_position()

	move_and_slide()

	# Check for damage during active attack frames
	if is_attacking:
		_check_attack_hit()


func _start_attack(animation_name: String, damage: int) -> void:
	is_attacking = true
	attack_has_hit = false
	current_attack_damage = damage

	animated_sprite.play(animation_name)

	# Play attack sound
	_play_attack_sound(animation_name)


func _play_attack_sound(animation_name: String) -> void:
	if attack_sound == null:
		return

	match animation_name:
		"light_punch":
			attack_sound.stream = PUNCH_SOUND

		"light_kick":
			attack_sound.stream = KICK_SOUND

		_:
			return

	attack_sound.play()


func _check_attack_hit() -> void:
	print("Red hitbox overlaps: ", hitbox.get_overlapping_areas())

	if attack_has_hit:
		return

	# Frames 2 and 3 are active attack frames
	if animated_sprite.frame < 2 or animated_sprite.frame > 3:
		return

	for area in hitbox.get_overlapping_areas():
		if area.name != "Hurtbox":
			continue

		var target = area.get_parent()

		if target == self:
			continue

		if target.has_method("take_damage"):
			target.take_damage(current_attack_damage)
			attack_has_hit = true
			break


func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health)

	if health == 0:
		defeated.emit()


func reset_health() -> void:
	health = max_health
	is_attacking = false
	attack_has_hit = false
	current_attack_damage = 0
	velocity = Vector2.ZERO

	animated_sprite.play("idle")
	_update_sprite_position()
	health_changed.emit(health)


func _update_hitbox_direction() -> void:
	if animated_sprite.flip_h:
		hitbox.position.x = -hitbox_distance
	else:
		hitbox.position.x = hitbox_distance


func change_animation(new_animation: String) -> void:
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)


func _update_sprite_position() -> void:
	match animated_sprite.animation:
		"walk":
			animated_sprite.position.y = walk_position_y

		_:
			animated_sprite.position.y = idle_position_y


func _on_animation_finished() -> void:
	if animated_sprite.animation == "light_punch" \
	or animated_sprite.animation == "light_kick":
		is_attacking = false
		attack_has_hit = false
