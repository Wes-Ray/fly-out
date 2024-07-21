extends Control


@export var tutorial_level : String = "res://levels/test_level.tscn"
@export var play_level : String = "res://levels/basic_track_level.tscn"

func _on_play_pressed() -> void:
	print("pressed")
	get_tree().change_scene_to_file(play_level)

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file(tutorial_level)
