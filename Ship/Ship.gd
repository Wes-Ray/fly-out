extends CharacterBody3D

# # Draft Keyboard Controls
# # Throttle/Brake: W and S
# # Yaw: A and D 
# # Roll: left and right arrow
# # Pitch: up and down down arrow

@export var speed : float = 100.0
@export var yaw_speed : float = 0.08

var throttle : float  # current throttle input
var move_vel : Vector3  # tracks moving velocity
var move_speed : float  # tracks current speed in the direction the ship is looking

func _physics_process(delta) -> void:

	# TODO: move to global/menu
	if Input.is_action_just_released("ui_cancel"): get_tree().quit()

	velocity = move_ship(delta)
	move_and_slide()


func move_ship(delta) -> Vector3:
	move_vel = Vector3.ZERO

	var yaw_input : float = Input.get_axis("yaw_right", "yaw_left")
	rotation.y += yaw_input * yaw_speed

	throttle = Input.get_axis("brake", "gas")
	# move_vel.x += throttle * speed
	var translate_dir : Vector3 = Vector3.ZERO
	translate_dir.x = throttle * speed
	move_vel = translate_dir.rotated(Vector3.UP, rotation.y + TAU/4)


	return move_vel
