extends CharacterBody3D

# Nodes

# Multiplayer nodes

@onready var MPS = $MultiplayerSynchronizer

# Hitbox nodes

@onready var interaction_hitbox = $Hitboxes/InteractionHitbox
@onready var kick_hitbox = $Hitboxes/KickHitbox

# Visual nodes

@onready var camera_mount = $CameraMount
@onready var anim = $Visuals/mixamo_base/AnimationPlayer
@onready var visuals = $Visuals

# Message scene

@export var message_entity = preload("res://scenes/entities/message.tscn")

# HUD nodes

@onready var message_box = $HUD/MessageBox
@onready var message = $HUD/MessageBox/Message
@onready var death_screen = $HUD/DeathScreen

# Create message HUD nodes

@onready var write_message_box = $HUD/WriteMessage
@onready var write_message_textbox = $HUD/WriteMessage/MessageBox

# 	Player Stats

@onready var health_bar = $HUD/PlayerStatistic/HealthBar
@onready var stamina_bar = $HUD/PlayerStatistic/StaminaBar
@onready var player_id_label = $HUD/PlayerStatistic/PlayerID
@onready var player_name_label = $HUD/PlayerStatistic/PlayerName

# Speed vars

var SPEED = 3
const JUMP_VELOCITY = 4.5

var walking_speed = 3.0
var running_speed = 5.0
var lerp_speed = 10.0

# Stats vars

var health = 100
var stamina = 100

var stamina_decrease_speed = 10
var stamina_regeneration_speed = 5
# States vars

var dead = false
var running = false
var is_locked = false
var ext_hud_open = false

# Mouse vars

@export var sens_horizontal = 0.5
@export var sens_vertical = 0.5

# Control vars

var mouse_unlocked = true
var movement_unlocked = true

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player multiplayer vars

@onready var player_id = GameManager.Players[multiplayer.get_unique_id()].id
@onready var player_name = GameManager.Players[multiplayer.get_unique_id()].name

# _ready process

func _ready():
	# Set mouse mode capture when enter scene
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set mp authority to ID
	MPS.set_multiplayer_authority(str(name).to_int())
	
	if MPS.get_multiplayer_authority() == multiplayer.get_unique_id():
		player_id_label.text = str(MPS.get_multiplayer_authority())
		player_id = MPS.get_multiplayer_authority()
		$CameraMount/SpringArm3D/Camera3D.set("current", true)
		$HUD.show()
	else:
		$CameraMount/SpringArm3D/Camera3D.set("current", false)
		$HUD.hide()
	player_id_label.text = "Player ID: " + str(player_id)
	if player_name == "":
		player_name = "null"
	player_name_label.text = "Player name: " + player_name

# mouse input process

func _input(event):
	
	
	if MPS.get_multiplayer_authority() == multiplayer.get_unique_id():
		if event is InputEventMouseMotion and mouse_unlocked:
			rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
			
			visuals.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
			
			camera_mount.rotate_x(deg_to_rad(event.relative.y * sens_vertical))
			
			camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-89), deg_to_rad(45))

# physic process

func _physics_process(delta):
	# Check if id is equal to authority 
	# if not - disables input
	if MPS.get_multiplayer_authority() == multiplayer.get_unique_id():
		
		refresh_hud()
		
		# Interactions
		
		handle_interactions()
		
		handle_write_message()
		
		# Combat
		
		var damage =  25
		
		handle_kick(damage)
		
		# Movement
		
		Movement(delta)

# Movement

func Movement(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	staminaHandle(delta)

	if  Input.is_action_pressed("running") and is_on_floor() and stamina > 0:
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	
	var input_dir = Input.get_vector("left", "right", "forward", "backward")


	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		if !is_locked:
			visuals.look_at(position + direction)
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			if running:
				startAnimation("running")
			else:
				startAnimation("walking")
	else:
		if !is_locked:
			startAnimation("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	if !is_locked:
		move_and_slide()

func staminaHandle(delta):
	if running:
		stamina -= delta * stamina_decrease_speed
	else:
		await get_tree().create_timer(3).timeout
		stamina += delta * stamina_regeneration_speed




# Interactions

# Interact whit other objects
func handle_interactions():
	if Input.is_action_just_pressed("interaction") and not ext_hud_open:
		for body in interaction_hitbox.get_overlapping_bodies():
			if body.has_method("interact"):
				body.interact()

func handle_write_message():
	if Input.is_action_just_pressed("message"):
		anim.stop()
		write_message_box.show()
		mouse_show()

# Write messages
@rpc("any_peer", "call_local")
func create_message(text):
	var m = message_entity.instantiate()
	get_tree().get_root().add_child(m)
	m.text = text
	m.global_transform.origin = global_transform.origin
	m.rotation.y = rotation.y
	mouse_show()

# HUD related functions

# display message function
# Used to call from outside
func display_message(text):
	message_box.show()
	message.text = text

# Same purpose as display_message(text) function
func hide_message():
	message_box.hide()

func _on_write_message_pressed():
	create_message.rpc(write_message_textbox.text)
	write_message_box.hide()
	mouse_hide()

func refresh_hud():
	health_bar.value = health
	stamina_bar.value = stamina

func mouse_hide():
	mouse_unlocked = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func mouse_show():
	mouse_unlocked = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Combat

func handle_kick(_damage):
	if Input.is_action_just_pressed("kick"):
		is_locked = true
		startAnimation("kick")
		for body in kick_hitbox.get_overlapping_bodies():
			if body.has_method("hit"):
				body.hit.rpc(_damage)
		await anim.animation_finished
		is_locked = false

@rpc("any_peer", "call_local")
func hit(_damage):
	health -= _damage
	# Debug string
	# print(player_id + " taken " + str(_damage) + " damage")

func death():
	if health <= 0:
		death_screen.show()

# Animation

func startAnimation(animation):
	if anim.current_animation != animation:
		anim.play(animation)
