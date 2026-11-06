extends Node2D

@export var damage_amount : float = 20
@export var knoc_dir : float = 0
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("take_damage"):
		body.take_damage(damage_amount, knoc_dir)
