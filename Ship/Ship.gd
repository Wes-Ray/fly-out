extends CharacterBody3D

# Draft Controls
# Throttle/Brake: Triggers or W and S
# Yaw: Left Joystick or A and D 
# Roll: Right Joystick or left and right arrow
# Pitch: Right Joystick or up and down down arrow

@onready var cast_center: = $cast_center
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
@export var ground_gravity: float = 4

var throttle: float  # current throttle input
var current_speed: float  # tracks current acceleration in the direction the ship is looking
var rotate_input: Vector3  # tracks current input for rotation (pitch, roll, yaw)
var is_stalling: bool  # tracks whether ship is currently stalling

var velocity_vertical_component: float  # tracks vertical component for gravity purposes


# TODO: might want to return distance_squared_to()
func raycast_distance(raycast: RayCast3D) -> float:
	if not raycast.is_colliding():
		# TODO: return error value or don't allow value to be set
		# could also default to max length? 
		return 404
	return global_transform.origin.distance_to(raycast.get_collision_point())


func move_ship_grounded(delta: float) -> void:
	var forward: = -basis.z

	# TODO: rotate/steer/pitch?
	rotate(basis.y.normalized(), rotate_input.y * air_yaw_speed * delta)
	# TODO: update for ground specific pitch
	# rotate(basis.x.normalized(), rotate_input.x * air_pitch_speed * 0.5 * delta)


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

	# handle auto-pitch to surface
	HUD.debug("cast_front", raycast_distance(cast_front))
	HUD.debug("cast_rear", raycast_distance(cast_rear))
	var front_rear_diff: = raycast_distance(cast_front) - raycast_distance(cast_rear)
	HUD.debug("front_rear_diff", front_rear_diff)
	rotate(basis.x.normalized(), -front_rear_diff * delta)

	# handle auto-roll to surface
	var left_right_diff: = raycast_distance(cast_left) - raycast_distance(cast_right)
	HUD.debug("left_right_diff", left_right_diff)
	rotate(basis.z.normalized(), left_right_diff * delta)
	
	# handle ground effect sucking down to ground
	HUD.debug("cast_center", raycast_distance(cast_center))

	# debug movement
	# velocity.y += rotate_input.x * delta * 10
	# velocity += forward * throttle * delta * 10

	# TODO: handle colliding with walls, likely have to reset current_speed to velocity.length()

	velocity = forward * current_speed
	move_and_slide()


func move_ship_flying(delta: float) -> void:


	#
	# TODO: should I be just saving/updating the gravity vel component 
	# separately and adding it back in? This might reduce the need for
	# a stall mechanic
	#

	HUD.debug("cast_center", raycast_distance(cast_center))
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
	var grounded:= true
	HUD.debug("grounded", grounded)
	if grounded: is_stalling = false  # always disable stalling when grounded
	return grounded


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
