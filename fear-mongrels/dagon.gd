extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -550.0

# Adjust this in the Inspector if walking looks too high.
@export var walk_offset_y: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity: float = 980.0
var is_attacking: bool = false

var original_sprite_offset: Vector2


func _ready() -> void:
	# Remember the existing sprite offset.
	original_sprite_offset = animated_sprite.offset

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)

	_update_sprite_offset()


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	# Face movement direction
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# Light punch
	if Input.is_action_just_pressed("punch") and not is_attacking:
		is_attacking = true
		animated_sprite.play("light_punch")

	# Light kick
	elif Input.is_action_just_pressed("kick") and not is_attacking:
		is_attacking = true
		animated_sprite.play("light_kick")

	# Normal animations
	if not is_attacking:
		if not is_on_floor():
			change_animation("jump")
		elif direction != 0:
			change_animation("walk")
		else:
			change_animation("idle")

	# Update artwork position without moving collision.
	_update_sprite_offset()

	move_and_slide()


func change_animation(new_animation: String) -> void:
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)


func _update_sprite_offset() -> void:
	if animated_sprite.animation == "walk":
		animated_sprite.offset = original_sprite_offset + Vector2(
			0.0,
			walk_offset_y
		)
	else:
		animated_sprite.offset = original_sprite_offset


func _on_animation_finished() -> void:
	if animated_sprite.animation == "light_punch" or animated_sprite.animation == "light_kick":
		is_attacking = false
