extends Control

func _ready() -> void:
	pass

func _on_button_pressed() -> void:
	print("Button clicked! Starting game...")
	get_tree().change_scene_to_file("res://workshop.tscn")
