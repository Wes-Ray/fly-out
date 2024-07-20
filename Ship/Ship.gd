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


# TODO: remove air_acceleration and only allow ground acceleration?
@export var air_acceleration: float = 10
@export var air_decceleration: float = 10
@export var air_yaw_speed: float = 1.5
@export var air_pitch_speed: float = 4
@export var air_roll_speed: float = 4
@export var air_friction: float = 4
@export var air_max_speed: float = 70
@export var air_min_speed: float = 10
@export var air_gravity: float = 14
@export var air_stall_acceleration: float = 10
@export var air_stall_recovery_angle: float = deg_to_rad(70)

@export var ground_acceleration: float = 8
@export var ground_yaw_speed: float = 2
@export var ground_friction: float = 5000
@export var ground_max_speed: float = 150
@export var ground_gravity: float = 20
@export var ground_hover_target_height: float = 1

var throttle: float  # current throttle input
var current_speed: float  # tracks current acceleration in the direction the ship is looking
var rotate_input: Vector3  # tracks current input for rotation (pitch, roll, yaw)
var is_stalling: bool  # tracks whether ship is currently stalling

var velocity_vertical_component: float  # tracks vertical component for gravity purposes


# TODO: might want to return distance_squared_to()
func raycast_distance(raycast: RayCast3D) -> float:
	assert(raycast.is_colliding(), "getting raycast distance when there is no collision")
	return global_transform.origin.distance_to(raycast.get_collision_point())


func move_ship_grounded(delta: float) -> void:
	var forward: = -basis.z

	# TODO: rotate/steer/pitch?
	rotate(basis.y.normalized(), rotate_input.y * air_yaw_speed * delta)
	# TODO: update for ground specific pitch
	HUD.debug("pitch", rotate_input.x)
	rotate(basis.x.normalized(), rotate_input.x * air_pitch_speed * 0.5 * delta)


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
	
	# TODO: add checks for valid raycast distance calcs, if raycast dist isn't valid, 
	# should NOT be sending it to rotate calc
	# TODO: more gradually rotate with lerp or similar effect

	# don't auto-adjust to surface if raycast is not colliding
	if ( cast_front.is_colliding() and cast_rear.is_colliding() and 
		 cast_left.is_colliding() and cast_right.is_colliding() ):

		# handle auto-pitch to surface
		var front_rear_diff: = raycast_distance(cast_front) - raycast_distance(cast_rear)
		HUD.debug("front_rear_diff", front_rear_diff)
		rotate(basis.x.normalized(), -front_rear_diff * delta)

		# handle auto-roll to surface
		var left_right_diff: = raycast_distance(cast_left) - raycast_distance(cast_right)
		HUD.debug("left_right_diff", left_right_diff)
		rotate(basis.z.normalized(), left_right_diff * delta)
	
	# suck to ground, max height based on length of raycast length
	HUD.debug("ground_detect", cast_ground_detector.is_colliding())
	if cast_center.is_colliding():
		velocity_vertical_component += -ground_gravity * delta #* raycast_distance(cast_center)
		velocity_vertical_component = max(-10, velocity_vertical_component)

	# elif cast_ground_detector.is_colliding():
		# velocity_vertical_component += ground_gravity * delta
	# elif:
	# 	velocity_vertical_component = -air_gravity
	# 	lerp()
		# handle ground effect sucking down to ground
		# HUD.debug("cast_center", raycast_distance(cast_center))
		# # TODO: add vertical component
		# var hover_height:float = raycast_distance(cast_center)
		# var distance_to_hover_height:float = abs(ground_hover_target_height - hover_height)
		# # TODO: might want to make these exponential/related to hover height directly (more distance, higher grav change)
		# if hover_height > 1.6:
		# 	velocity_vertical_component -= ground_gravity * (distance_to_hover_height**2) * delta
		# elif hover_height < 1.0:
		# 	velocity_vertical_component += ground_gravity * (distance_to_hover_height**2) * delta


	# debug movement
	# velocity.y += rotate_input.x * delta * 10
	# velocity += forward * throttle * delta * 10

	# TODO: handle colliding with walls, likely have to reset current_speed to velocity.length()

	if Input.is_action_pressed("debug1"):
		velocity_vertical_component -= ground_gravity * delta
	if Input.is_action_pressed("debug2"):
		velocity_vertical_component += ground_gravity * delta
	
	HUD.debug("vert_component", velocity_vertical_component)

	velocity = forward * current_speed
	# TODO: add constant for this
	# TODO: this should potentially be based off of angle compared to track? input prob works for now
	if not rotate_input.x > 0.08:
		velocity.y = velocity_vertical_component
	move_and_slide()


func move_ship_flying(delta: float) -> void:


	#
	# TODO: should I be just saving/updating the gravity vel component 
	# separately and adding it back in? This might reduce the need for
	# a stall mechanic
	#

	var forward: = -basis.z
	var horizon: = Vector3(forward.x, 0, forward.z).normalized()

	rotate(basis.z.normalized(), rotate_input.z * air_roll_speed * delta)
	rotate(basis.x.normalized(), rotate_input.x * air_pitch_speed * delta)
	rotate(basis.y.normalized(), rotate_input.y * air_yaw_speed * delta)

	HUD.debug("throttle", throttle)
	HUD.debug("current_speed", current_speed)
	HUD.debug("velocity.length", velocity.length())

	if throttle > 0 and current_speed < air_max_speed:
		current_speed += throttle * air_acceleration * delta
	elif throttle < 0 and current_speed > air_min_speed:
		current_speed += throttle * air_decceleration * delta
	
	# Affect current speed based on angle to horizon, current speed, and gravity.
	# Going over a min lift speed should allow level flight when pointing straight at the horizon

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
	if (is_stalling and 
			velocity.length() > air_min_speed and 
			forward.angle_to(Vector3.DOWN) < air_stall_recovery_angle):
		is_stalling = false
		current_speed = velocity.length()

	if is_stalling:
		velocity += forward * throttle * air_stall_acceleration * delta
		velocity.y += -air_gravity * delta
	else:
		velocity = forward * current_speed
	
	HUD.debug("is_stalling", is_stalling)
	move_and_slide()


func is_grounded() -> bool:
	var grounded:bool = cast_ground_detector.is_colliding()
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

	# TODO: move to global/menu
	if Input.is_action_just_released("ui_cancel"): get_tree().quit()
	move_ship(delta)
