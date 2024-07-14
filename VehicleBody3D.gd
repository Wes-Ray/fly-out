extends VehicleBody3D

@export var MAX_STEER := 1.0
@export var STEER_FORCE := 18
@export var ENGINE_POWER := 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	steering = move_toward(steering, Input.get_axis("right", "left") * MAX_STEER, delta * STEER_FORCE)
	engine_force = Input.get_axis("brake", "gas") * ENGINE_POWER
