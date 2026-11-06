extends CharacterBody2D

enum State {idle , follow , stoping, attack , die, fall}

@export var gravity_force : float = 980
@export var run_speed : float = 80
@export var jump_force : float = 300
@export var attack_damage : Vector2i = Vector2i(5, 10)
@export var attack_cooldown : float = .5
@export var attack_duration : float = .2
@export var enemy_color : Color 

@export var healt : float = 100
@export var attack_range : float = 40
@export var follow_range : float = 200
@export var player : CharacterBody2D
@export var time_2_accel : float = .16
@export var time_2_decel : float = .1
@export var knockback_force : Vector2 = Vector2(250, -150)
var current_state = State.idle
var current_jumps : int = 0
var facing_direction : float = 1
var is_attacking : bool = false
var can_attack : bool = true
var has_he_attacked : bool = false
var attack_time : float = .0
var is_taking_damage : bool = false

@onready var hp :float = healt
@onready var enemy_animation: AnimatedSprite2D = $enemy_sprite
@onready var left_area: CollisionShape2D = $atack_area/left_area
@onready var right_area: CollisionShape2D = $atack_area/right_area
@onready var atack_area: Area2D = $atack_area
@onready var accel : float= run_speed / time_2_accel
@onready var decel : float = run_speed / time_2_decel


func _ready() -> void:
	add_to_group("enemys")
	enemy_animation.modulate = enemy_color

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		gravity(delta, gravity_force)
	
	var direction : float = get_direction()
	facing_direction = get_facing_direction(direction) if get_facing_direction(direction) != null else facing_direction
	var distance_to_player : float = cal_distance()

	state_handler(direction, distance_to_player)
	flip_enemy_sprite(facing_direction)
	controle_hit_box(facing_direction)

	if is_taking_damage:
		enemy_animation.play("damaged")
		velocity.x = move_toward(velocity.x, 0, decel * 0.5 * delta)
	else:
		match current_state:
			State.idle:
				enemy_animation.play("idle")
				idle()
			State.follow:
				enemy_animation.play("run")
				run(direction, delta, accel)
			State.attack:
				enemy_animation.play("attack ")
				attack(delta)
			State.stoping:
				stoping(delta, decel)
			State.fall:
				pass
			State.die:
				die()
	move_and_slide()

@warning_ignore("shadowed_variable")
func state_handler(direction : float, distance_to_player : float):
	if hp <= 0:
		current_state = State.die
		return
	if is_attacking or is_taking_damage:
		return
	if attack_range >= distance_to_player:
		if can_attack:
			current_state = State.attack
			is_attacking = true
			can_attack = false
			attack_time = attack_duration
		else:
			current_state = State.idle
	elif follow_range >= distance_to_player:
		current_state = State.follow
	elif !is_on_floor() || velocity.y > 0:
		current_state = State.fall
	else:
		if velocity.x != 0:
			current_state = State.stoping
		else:
			current_state = State.idle
	
func idle():
	velocity.x = 0

func run(direction : float, delta : float, accel_fact : float):
	velocity.x = move_toward(velocity.x, direction * run_speed, delta * accel_fact)

func stoping(delta : float, decel_fact : float):
	velocity.x = move_toward(velocity.x, 0 , delta * decel_fact)

func jump():
	velocity.y = -jump_force
	current_jumps += 1

func gravity(delta : float, force : float):
	velocity.y += force * delta

func get_facing_direction(direction : float):
	if direction > 0: 
		return 1
	elif direction < 0: 
		return -1

@warning_ignore("shadowed_variable")
func flip_enemy_sprite(facing_direction : float):
	if facing_direction == 1: 
		enemy_animation.flip_h = false
	elif facing_direction == -1: 
		enemy_animation.flip_h = true

func attack(delta : float):
	attack_time -= delta
	var random_damage = randi_range(attack_damage.x, attack_damage.y)
	velocity = Vector2.ZERO
	var bodies = atack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage") and !has_he_attacked:
			body.take_damage(random_damage, facing_direction)
			has_he_attacked = true
	if attack_time <= 0:
		is_attacking = false
		current_state = State.idle
		has_he_attacked = false
		start_attack_cooldown()

func start_attack_cooldown():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func controle_hit_box(facing_direction):
	if is_attacking:
		if facing_direction == 1:
			right_area.disabled = false
			left_area.disabled = true
		elif facing_direction == -1:
			right_area.disabled = true
			left_area.disabled = false
	else : 
		right_area.disabled = true
		left_area.disabled = true

func die():
	queue_free()

func take_damage(amount : float, knockback_dir : float = 0):
	hp -= amount
	if hp <= 0:
		die()
		return
	if knockback_dir == 0 and player:
		knockback_dir = sign(global_position.x - player.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
	is_taking_damage = true
	enemy_animation.play("damaged")
	enemy_animation.modulate = Color("#ff6046")
	if is_attacking:
		is_attacking = false
		has_he_attacked = false
		start_attack_cooldown()
	current_state = State.idle
	velocity = Vector2(knockback_dir * knockback_force.x, knockback_force.y)
	await get_tree().create_timer(0.25).timeout
	enemy_animation.modulate = enemy_color
	is_taking_damage = false

func get_direction() -> float:
	if !player: return 0.0
	return sign(player.global_position.x - global_position.x)

func cal_distance() -> float:
	if !player: return INF
	return global_position.distance_to(player.global_position)
