extends CharacterBody3D

# # Draft Keyboard Controls
# # Throttle/Brake: W and S
# # Yaw: A and D 
# # Roll: left and right arrow
# # Pitch: up and down down arrow

@export var speed : float = 100
@export var yaw_speed : float = 4
@export var pitch_speed : float = 4
@export var roll_speed : float = 4

var throttle : float  # current throttle input
var move_speed : float  # tracks current speed in the direction the ship is looking
var rotate_input : Vector3  # tracks current input for rotation (pitch, roll, yaw)

func _physics_process(delta : float) -> void:

	# TODO: move to global/menu
	if Input.is_action_just_released("ui_cancel"): get_tree().quit()

	move_ship(delta)


func move_ship(delta : float) -> void:

	# Yaw
	rotate_input.y = Input.get_axis("yaw_right", "yaw_left")	
	# Pitch
	rotate_input.x = Input.get_axis("pitch_down", "pitch_up")
	# Roll
	rotate_input.z = Input.get_axis("roll_right", "roll_left")
	
	# Translate forward/back
	throttle = Input.get_axis("brake", "gas")

	rotate(basis.z, rotate_input.z * roll_speed * delta)
	rotate(basis.x, rotate_input.x * pitch_speed * delta)
	rotate(basis.y, rotate_input.y * yaw_speed * delta)

	velocity = -basis.z * throttle * speed
	move_and_slide()
