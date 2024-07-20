extends CanvasLayer

@onready var debug_label:= $debug_label

var debug_dict:= {}


func debug(debug_name: String, value: Variant = "") -> void:
	debug_dict[debug_name] = value
	
	var result_str:= ""
	for key: String in debug_dict.keys():
		result_str += key + ": " + str(debug_dict[key]) + "\n"
	
	debug_label.text = result_str
