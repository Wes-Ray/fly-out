extends CanvasLayer

@onready var debug_label: = $debug_label
@onready var checkpoint_display: = $Control/lap_display
@onready var timer_display: = $Control/timer_display

var debug_dict:= {}
var active: = false


func debug(debug_name: String, value: Variant = "") -> void:
	if not OS.is_debug_build():
		return

	debug_dict[debug_name] = value
	
	var result_str:= ""
	for key: String in debug_dict.keys():
		result_str += key + ": " + str(debug_dict[key]) + "\n"
	
	debug_label.text = result_str


func display_time(lap_time: float) -> void:
	if not active:
		return

	timer_display.text = str("%0.3f" % lap_time)


func update_checkpoint(checkpoint_list: Variant, _current_lap_idx: int, _finish: bool = false) -> void:
	active = true
	var scoreboard: = ""
	for i: int in range(checkpoint_list.size()):
		scoreboard += "LAP: " + str(i + 1) + "\n"
		for y: int in range(checkpoint_list[i].size()):
			if y == 0:
				continue
			scoreboard += str("%0.3f" % checkpoint_list[i][y]) + "\n"
	checkpoint_display.text = scoreboard
