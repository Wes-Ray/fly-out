extends CharacterBody3D

# Draft Controls
# Throttle/Brake: Triggers or W and S
# Yaw: Left Joystick or A and D 
# Roll: Right Joystick or left and right arrow
# Pitch: Right Joystick or up and down down arrow

@onready var cast_center: = $cast_center
@onready var cast_ground_detector: = $cast_ground_detector
@onready var cast_front: = $cast_front
@onready var cast_rear: = $cast_rear
@onready var cast_left: = $cast_left
@onready var cast_right: = $cast_right

@onready var bumper_front_left: = $bumper_front_left
@onready var bumper_front_right: = $bumper_front_right

@export var air_acceleration: float = 10
@export var air_decceleration: float = 10

@export var air_yaw_acceleration: float = 1.5
@export var air_yaw_decceleration: float = 4
@export var air_yaw_max_speed: float = 2

@export var air_roll_acceleration: float = 3
@export var air_roll_decceleration: float = 6
@export var air_roll_max_speed: float = 4
@export var air_roll_decay_speed: float = 40

@export var air_pitch_acceleration: float = 3
@export var air_pitch_decceleration: float = 6
@export var air_pitch_max_speed: float = 4
@export var air_pitch_decay_speed: float = 3

@export var air_friction: float = 1
@export var air_max_speed: float = 70
@export var air_min_speed: float = 10
@export var air_gravity: float = 14
@export var air_stall_acceleration: float = 10
@export var air_stall_recovery_angle: float = deg_to_rad(70)

@export var ground_acceleration: float = 8

@export var ground_yaw_acceleration: float = 3
@export var ground_yaw_decceleration: float = 6
@export var ground_yaw_max_speed: float = 1.2

@export var ground_pitch_acceleration: float = 6 
@export var ground_pitch_decceleration: float = 4
@export var ground_pitch_max_speed: float = 2

@export var ground_roll_acceleration: float = 6 
@export var ground_roll_decceleration: float = 4
@export var ground_roll_max_speed: float = 2

@export var ground_friction: float = 1.5
@export var ground_max_speed: float = 80
@export var ground_gravity: float = 14
@export var ground_auto_pitch_speed: float = 8
@export var ground_auto_roll_speed: float = 8
@export var ground_suction_angle_offset: float = deg_to_rad(-2)
@export var ground_strafe_angle_offset: float = deg_to_rad(10)

@export var ground_bumper_bounce_speed: float = 1.5
@export var ground_bumper_friction: float = 100
@export var ground_bumper_min_speed: float = 10

var throttle: float  # current throttle input
var current_speed: float  # tracks current acceleration in the direction the ship is looking
var rotate_input: Vector3  # tracks current input for rotation (pitch, roll, yaw)
var is_stalling: bool  # tracks whether ship is currently stalling
var grounded: bool  # tracks current grounded state (updated in func is_grounded())

var current_yaw_speed: float
var current_roll_speed: float
var current_pitch_speed: float


# returns raycast distance to collider, this should not be called if raycast is not colliding
func raycast_distance(raycast: RayCast3D) -> float:
	assert(raycast.is_colliding(), "getting raycast distance when there is no collision")
	return global_transform.origin.distance_to(raycast.get_collision_point())


# returns a new current rotation speed
func update_rotation_speed(	current_rotation_speed: float, 
							current_input: float,
							rotation_acceleration: float,
							rotation_decceleration: float,
							max_rotation_speed: float,
							delta: float) -> float:

	if not is_zero_approx(current_input):
		if sign(current_rotation_speed) != current_input:
			current_rotation_speed += current_input * rotation_decceleration * delta
		current_rotation_speed += current_input * rotation_acceleration * delta
		current_rotation_speed = clampf(current_rotation_speed, -max_rotation_speed, max_rotation_speed)
	else:
		current_rotation_speed = move_toward(current_rotation_speed, 0, rotation_decceleration * delta)

	return current_rotation_speed


func move_ship_grounded(delta: float) -> void:
	var forward: = -basis.z
	var tilted_basis: = basis.rotated(basis.x, ground_suction_angle_offset)

	var horizon: = Vector3(forward.x, 0, forward.z).normalized()

	current_yaw_speed = update_rotation_speed(current_yaw_speed, rotate_input.y, ground_yaw_acceleration, ground_yaw_decceleration, ground_yaw_max_speed, delta)
	rotate(basis.y.normalized(), current_yaw_speed * delta)
	HUD.debug("current_yaw_speed", current_yaw_speed)

	# current_roll_speed = update_rotation_speed(current_roll_speed, rotate_input.z, ground_roll_acceleration, ground_roll_decceleration, ground_roll_max_speed, delta)
	# HUD.debug("current_roll_speed", current_roll_speed)

	HUD.debug("throttle", throttle)
	HUD.debug("current_speed", current_speed)
	HUD.debug("velocity.length", velocity.length())

	# TODO: check if this will work without the physics collision box
	# magnetically stick to surface until player pitches up or an extremely sharp drop-off

	# I want to get the front/back raycast distances to the nearest ground and adjust the velocity to keep
	# those as close as possible to a certain goal hover height

	if throttle > 0 and current_speed < ground_max_speed:
		current_speed += throttle * ground_acceleration * delta
	elif throttle < 0 and current_speed > -ground_max_speed:
		current_speed += throttle * ground_acceleration * delta
	
	current_pitch_speed = update_rotation_speed(current_pitch_speed, rotate_input.x, ground_pitch_acceleration, ground_pitch_decceleration, ground_pitch_max_speed, delta)
	current_roll_speed = update_rotation_speed(current_roll_speed, rotate_input.z, ground_roll_acceleration, ground_roll_decceleration, ground_roll_max_speed, delta)

	# don't auto-adjust to surface if raycast is not colliding
	if ( cast_front.is_colliding() and cast_rear.is_colliding() and 
		 cast_left.is_colliding() and cast_right.is_colliding() ):

		# handle auto-pitch to surface and add current_pitch_speed from input
		var front_rear_diff: = raycast_distance(cast_front) - raycast_distance(cast_rear)
		HUD.debug("front_rear_diff", front_rear_diff)
		rotate(basis.x.normalized(), -front_rear_diff * ground_auto_pitch_speed * delta + current_pitch_speed * delta)

		# handle auto-roll to surface
		var left_right_diff: = raycast_distance(cast_left) - raycast_distance(cast_right)
		HUD.debug("left_right_diff", left_right_diff)
		rotate(basis.z.normalized(), left_right_diff * ground_auto_roll_speed * delta + current_roll_speed * delta)

		# add strafe movement by re-orienting the tilted basis based on input instead of roll angle
		if not is_zero_approx(rotate_input.z):
			tilted_basis = tilted_basis.rotated(tilted_basis.y, rotate_input.z * ground_strafe_angle_offset)
	
	# rotate if hitting wall
	if bumper_front_left.is_colliding():
		rotate(basis.y.normalized(), -ground_bumper_bounce_speed * delta)
		if current_speed > ground_bumper_min_speed:
			current_speed -= ground_bumper_friction * delta
	if bumper_front_right.is_colliding():
		rotate(basis.y.normalized(), ground_bumper_bounce_speed * delta)
		if current_speed > ground_bumper_min_speed:
			current_speed -= ground_bumper_friction * delta

	# apply gravity to current speed
	var angle_to_horizon: float
	angle_to_horizon = forward.angle_to(horizon)
	if forward.dot(Vector3.UP) < 0:
		angle_to_horizon = -angle_to_horizon
	HUD.debug("angle_to_horizon", angle_to_horizon)
	current_speed += -angle_to_horizon * ground_gravity * delta

	if current_speed > 0:
		var tilted_forward: = -tilted_basis.z
		velocity = tilted_forward * current_speed
	else:
		velocity = forward * current_speed

	# apply friction
	current_speed = move_toward(current_speed, 0, ground_friction * delta)

	move_and_slide()


func move_ship_flying(delta: float) -> void:

	# TODO: should be positive basis (refactor)
	var forward: = -basis.z
	var horizon: = Vector3(forward.x, 0, forward.z).normalized()

	current_yaw_speed = update_rotation_speed(current_yaw_speed, rotate_input.y, air_yaw_acceleration, air_yaw_decceleration, air_yaw_max_speed, delta)
	current_roll_speed = update_rotation_speed(current_roll_speed, rotate_input.z, air_roll_acceleration, air_roll_decceleration, air_roll_max_speed, delta)
	current_pitch_speed = update_rotation_speed(current_pitch_speed, rotate_input.x, air_pitch_acceleration, air_pitch_decceleration, air_pitch_max_speed, delta)
	if is_zero_approx(rotate_input.x):
		current_pitch_speed -= air_pitch_decay_speed * delta  # add decay
	if is_zero_approx(rotate_input.z):
		var rotation_correct_strength:float = clamp(-rotation.z, -0.2, 0.2)
		current_roll_speed += rotation_correct_strength * air_roll_decay_speed * delta  # add decay

	rotate(basis.y.normalized(), current_yaw_speed * delta)
	rotate(basis.z.normalized(), current_roll_speed * delta)
	rotate(basis.x.normalized(), current_pitch_speed * delta)

	HUD.debug("current_roll_speed", current_roll_speed)
	HUD.debug("current_yaw_speed", current_yaw_speed)

	HUD.debug("throttle", throttle)
	HUD.debug("current_speed", current_speed)
	HUD.debug("velocity.length", velocity.length())

	# throttle, disabled for actual game
	# if throttle > 0 and current_speed < air_max_speed:
	# 	current_speed += throttle * air_acceleration * delta

	# braking
	if throttle < 0 and current_speed > air_min_speed:
		current_speed += throttle * air_decceleration * delta
	
	# calculate angle to horizon
	# straight down is -90* or -tau/4, straight up is +, aligned with horizon is 0
	var angle_to_horizon: float
	angle_to_horizon = forward.angle_to(horizon)
	if forward.dot(Vector3.UP) < 0:
		angle_to_horizon = -angle_to_horizon
	HUD.debug("angle_to_horizon", angle_to_horizon)

	# apply gravity relative to angle to horizon
	current_speed += -angle_to_horizon * air_gravity * delta

	HUD.debug("angle_to_vel", forward.angle_to(velocity))

	if current_speed < -1:
		is_stalling = true
	if (	is_stalling and 
			velocity.length() > air_min_speed and 
			forward.angle_to(Vector3.DOWN) < air_stall_recovery_angle ):
		is_stalling = false
		current_speed = velocity.length()

	if is_stalling:
		velocity += forward * throttle * air_stall_acceleration * delta
		velocity.y += -air_gravity * delta
	else:
		velocity = forward * current_speed
	
	# apply friction
	current_speed = move_toward(current_speed, 0, air_friction * delta)
	
	HUD.debug("is_stalling", is_stalling)
	move_and_slide()


func is_grounded() -> bool:
	var new_grounded:bool = cast_ground_detector.is_colliding()

	# transitioning from grounded to not grounded
	if grounded and not new_grounded:
		current_pitch_speed = 0

	grounded = new_grounded

	if grounded: is_stalling = false  # always disable stalling when grounded
	HUD.debug("grounded", grounded)
	return grounded
	# return true
	# return false


func move_ship(delta: float) -> void:

	rotate_input.y = Input.get_axis("yaw_right", "yaw_left")
	rotate_input.x = Input.get_axis("pitch_down", "pitch_up")
	rotate_input.z = Input.get_axis("roll_right", "roll_left")
	
	throttle = Input.get_axis("brake", "gas")

	if is_grounded():
		move_ship_grounded(delta)
	else:
		move_ship_flying(delta)


func _physics_process(delta: float) -> void:
	HUD.debug("forward", -basis.z)

	HUD.debug("bumper_front_left", bumper_front_left.is_colliding())

	# TODO: move to global/menu
	if Input.is_action_just_released("ui_cancel"): get_tree().quit()
	move_ship(delta)
