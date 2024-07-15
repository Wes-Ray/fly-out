extends CanvasLayer

@onready var debug_label := $debug_label

var debug_dict := {}

func _ready() -> void:
	print("GLOBAL HUD")


func debug(name : String, value : Variant) -> void:
	debug_dict[name] = value
	
	var result_str := ""
	for key : String in debug_dict.keys():
		result_str += key + ": " + str(debug_dict[key]) + "\n"
	
	debug_label.text = result_str
