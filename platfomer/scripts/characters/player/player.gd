extends CharacterBody2D

@onready var player_animation: AnimatedSprite2D = $player_animation
@onready var atack_area: Area2D = $atack_area
@onready var left_area: CollisionShape2D = $atack_area/left_area
@onready var right_area: CollisionShape2D = $atack_area/right_area
@onready var healt_lable: Label = %healt
@onready var time_lable: Label = %time
@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

enum State {idle, run, jump, stoping, dash, fall, attack, die}
var current_state : State = State.idle

@export var gravity_force : float = 980
@export var run_speed : float = 200
@export var time_2_accel : float = .1
@export var time_2_decel : float = .1
@export var jump_force : float = 300
@export var max_jumps : int = 2
@export var dash_speed : float = 900
@export var dash_duration : float = .25
@export var dash_cooldown : float = 10
@export var attack_duration : float = .1
@export var attack_damage : Vector2i = Vector2i(5, 10)
@export var attack_cooldown : float = .3
@export var healt : float = 100
@export var knockback_force : Vector2 = Vector2(250, -150)
@onready var accel : float= run_speed / time_2_accel
@onready var decel : float = run_speed / time_2_decel
@onready var dash_accel : float = dash_speed / dash_duration
@onready var hp :float = healt

var current_jumps : int = 0
var is_dashing : bool = false
var can_dash : bool = true
var facing_direction : float = 1
var dash_time_left : float = .0
var is_attacking : bool = false
var can_attack : bool = true
var has_he_attacked : bool = false
var attack_time : float = .0
var is_taking_damage : bool = false
var time_elapsed : float = 0
var text : String
var seconds: int
var minutes: int


func _ready() -> void:
	add_to_group("player")
	
	
func _physics_process(delta: float) -> void:
	if !is_on_floor():
		gravity(delta, gravity_force)
	
	if !audio_stream_player_2d.playing:
		audio_stream_player_2d.play()
		
	if current_state == State.die:
		return
	time_elapsed += delta 
	minutes= int(time_elapsed) / 60
	seconds= int(time_elapsed) % 60
	text = "%02d:%02d" % [minutes, seconds]
	if hp > 0:
		healt_lable.text = "Hp: "+str(hp)
	else:
		healt_lable.text = "Dead!!"
		
	time_lable.text = "Time: "+str(text)
	var direction : float = Input.get_axis("left", "right")
	facing_direction = get_facing_direction(direction) if get_facing_direction(direction) != null else facing_direction
	
	resete_vars()
	state_handler(direction, facing_direction)
	flip_player_sprite(facing_direction)
	controle_hit_box(facing_direction)
	if !is_taking_damage:
		match current_state:
			State.idle:
				can_attack = true
				play_anim("idle")
				idle()
			State.jump:
				play_anim("jump")
				if direction != 0:
					run(direction, delta, accel)
			State.run:
				play_anim("run")
				run(direction, delta, accel)
			State.stoping:
				play_anim("stoping")
				stoping(delta, decel)
			State.dash:
				play_anim("run")
				dash(facing_direction, delta)
			State.fall: 
				play_anim("fall")
				if direction != 0:
					run(direction, delta, accel)
			State.attack:
				play_anim("attack ")
				attack(delta)
			State.die:
				play_anim("die")
	
	move_and_slide()

@warning_ignore("shadowed_variable")
func state_handler(direction : float, facing_direction : float):
	if hp <= 0:
		current_state = State.die
		return
	if is_dashing || is_attacking || is_taking_damage:
		return
	if Input.is_action_just_pressed("attack") && can_attack:
		current_state = State.attack
		is_attacking = true
		can_attack = false
		attack_time = attack_duration
	elif Input.is_action_just_pressed("dash") and can_dash and facing_direction != 0:
		current_state = State.dash
		is_dashing = true
		can_dash = false
		dash_time_left = dash_duration
		start_dash_cooldown()
	elif Input.is_action_just_pressed("jump") && current_jumps < max_jumps:
		jump()
		current_state = State.jump
	elif !is_on_floor():
		if velocity.y < 0:
			current_state = State.jump
		else:
			current_state = State.fall
	elif direction != 0:
		current_state = State.run
	else:
		if velocity.x != 0:
			current_state = State.stoping
		else:
			current_state = State.idle

func resete_vars():
	if is_on_floor() and velocity.y >= 0:
		current_jumps = 0

func idle():
	pass

func run(direction : float, delta : float, accel_fact : float):
	velocity.x = move_toward(velocity.x, direction * run_speed, delta * accel_fact)

func stoping(delta : float, decel_fact : float):
	velocity.x = move_toward(velocity.x, 0 , delta * decel_fact)

func jump():
	velocity.y = -jump_force
	current_jumps += 1

func gravity(delta : float, force : float):
	velocity.y += force * delta

func dash(direction : float, delta: float):
	velocity.y = 0
	velocity.x = move_toward(velocity.x, dash_speed * direction, dash_accel* delta)
	dash_time_left -= delta
	if dash_time_left <=0 :
		is_dashing = false
		current_state = State.idle

func start_dash_cooldown():
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func get_facing_direction(direction : float):
	if direction > 0: 
		return 1
	elif direction < 0: 
		return -1

@warning_ignore("shadowed_variable")
func flip_player_sprite(facing_direction : float):
	if facing_direction == 1: 
		player_animation.flip_h = false
	elif facing_direction == -1: 
		player_animation.flip_h = true

func attack(delta : float):
	attack_time -= delta
	var random_damage = randi_range(attack_damage.x, attack_damage.y)
	velocity = Vector2.ZERO
	var bodies = atack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemys") and body.has_method("take_damage") and !has_he_attacked:
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
	get_tree().paused = true
	velocity = Vector2.ZERO

func take_damage(amount : float, knockback_dir : float = 0):
	hp -= amount
	is_taking_damage = true
	is_attacking = false
	player_animation.play("damaged")
	velocity = Vector2(knockback_dir * knockback_force.x, knockback_force.y)
	await get_tree().create_timer(0.25).timeout
	is_taking_damage = false

func play_anim(anim_name: String):
	if !is_taking_damage or anim_name == "die":
		player_animation.play(anim_name)
