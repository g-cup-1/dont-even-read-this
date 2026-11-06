extends Node2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var jumppad_velocity : Vector2 = Vector2(0,-100)

func lunch(body : CharacterBody2D):
	animated_sprite_2d.play("activete")
	body.velocity = jumppad_velocity
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("disactivete")
	await animated_sprite_2d.animation_finished
	animated_sprite_2d.play("idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: 
		lunch(body)
