extends CharacterBody3D

# Draft Controls
# Throttle/Brake: Triggers or W and S
# Yaw: Left Joystick or A and D 
# Roll: Right Joystick or left and right arrow
# Pitch: Right Joystick or up and down down arrow

@export var acceleration : float = .5
@export var yaw_speed : float = 1.5
@export var pitch_speed : float = 4
@export var roll_speed : float = 4
@export var ground_friction : float = 5000
@export var max_speed : float = 150

var throttle : float  # current throttle input
var current_speed : float  # tracks current acceleration in the direction the ship is looking
var rotate_input : Vector3  # tracks current input for rotation (pitch, roll, yaw)
var gravity : float = 9.8  # can also ProjectSettings.get_setting("physics/3d/default_gravity") but don't see the point


func _physics_process(delta : float) -> void:

	# TODO: move to global/menu
	if Input.is_action_just_released("ui_cancel"): get_tree().quit()

	# HUD.debug("delta", delta)
	# HUD.debug("test", Input.is_action_pressed("gas"))

	move_ship(delta)


func move_ship_grounded(delta : float) -> void:
	HUD.debug("speed", current_speed)
	if throttle > 0 and current_speed < max_speed:
		current_speed += throttle * acceleration
		velocity += -basis.z * current_speed * delta
	elif throttle <= 0:
		current_speed -= ground_friction
		current_speed = max(0, current_speed)
		velocity += -basis.z * current_speed * delta
	velocity.y += -gravity * delta
	move_and_slide()


func move_ship_flying(delta : float) -> void:
	rotate(basis.z.normalized(), rotate_input.z * roll_speed * delta)
	rotate(basis.x.normalized(), rotate_input.x * pitch_speed * delta)
	rotate(basis.y.normalized(), rotate_input.y * yaw_speed * delta)

	# TODO: need to factor in angle of attack, potentially remove throttle input
	# velocity += -basis.z * throttle * acceleration * delta
	move_and_slide()


func is_grounded() -> bool:
	var grounded := true
	HUD.debug("grounded", grounded)
	return grounded


func move_ship(delta : float) -> void:

	# Yaw
	rotate_input.y = Input.get_axis("yaw_right", "yaw_left")
	# Pitch
	rotate_input.x = Input.get_axis("pitch_down", "pitch_up")
	# Roll
	rotate_input.z = Input.get_axis("roll_right", "roll_left")
	
	# Translate forward/back
	throttle = Input.get_axis("brake", "gas")

	if is_grounded():
		move_ship_grounded(delta)
	else:
		move_ship_flying(delta)
