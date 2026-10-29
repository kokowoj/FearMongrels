extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -550.0

# Adjust walking height in the Inspector.
@export var walk_offset_y: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity: float = 980.0
var is_attacking: bool = false

var original_sprite_offset: Vector2


func _ready() -> void:
	# Save the sprite's original offset.
	original_sprite_offset = animated_sprite.offset

	animated_sprite.animation_finished.connect(
		_on_animation_finished
	)

	_update_sprite_offset()


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Player 2 movement
	var direction := Input.get_axis("p2_left", "p2_right")
	velocity.x = direction * speed

	# Face movement direction
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	# Jump (W)
	if Input.is_action_just_pressed("p2_jump") and is_on_floor() and not is_attacking:
		velocity.y = jump_velocity

	# Light punch (E)
	if Input.is_action_just_pressed("p2_light_punch") and not is_attacking:
		is_attacking = true
		animated_sprite.play("light_punch")

	# Light kick (F)
	elif Input.is_action_just_pressed("p2_light_kick") and not is_attacking:
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

	# Adjust only the visible artwork.
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
