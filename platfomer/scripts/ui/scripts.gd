extends Control

const TEST_LEVEL = preload("res://scenes/levels/test_level.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit(0)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(TEST_LEVEL)
