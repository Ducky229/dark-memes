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

@export var message = preload("res://scenes/entities/message.tscn")

# HUD nodes

@onready var label = $HUD/MessageBox/Message
@onready var death_screen = $HUD/DeathScreen

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

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player multiplayer vars

var player_id : int
var player_name : String

# _ready process

func _ready():
	# Set mouse mode capture when enter scene
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set mp authority to ID
	MPS.set_multiplayer_authority(str(name).to_int())
	
	# Save mp authority as ID
	player_id = MPS.get_multiplayer_authority()
	
	# Display ID
	player_id_label.text = str(player_id)

# mouse input process

func _input(event):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		$camera_mount/SpringArm3D/Camera3D.set("current", true)
		$Control.show()
	else:
		$camera_mount/SpringArm3D/Camera3D.set("current", false)
		$Control.hide()
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		if event is InputEventMouseMotion and not ext_hud_open:
			rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
			visuals.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
			camera_mount.rotate_x(deg_to_rad(event.relative.y * sens_vertical))
			camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-89), deg_to_rad(45))

# physic process

func _physics_process(delta):
	# Check if id is equal to authority 
	# if not - disables input
	if player_id == multiplayer.get_unique_id():
		
		refresh_hud()
		
		
		# Interactions
		
		handle_interactions()
		
		handle_write_message()
		
		# Movement
		
		handle_gravity(delta)
		
		staminaHandle(delta)
		
		handle_running_states()
		
		handle_jump()
		
		# Combat
		
		var damage =  25
		
		handle_kick(damage) 
		
		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			handle_direction(direction)
		else:
			handle_not_locked()
		
		if !is_locked:
			move_and_slide()

func handle_not_locked():
	if !is_locked:
				if anim.current_animation != "idle":
					anim.play("idle")
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_direction(direction):
	if !is_locked:
		if running:
			if anim.current_animation != "running":
				anim.play("running")
		else:
				if anim.current_animation != "walking":
					anim.play("walking")
			visuals.look_at(position + direction)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

func handle_write_message():
	if Input.is_action_just_pressed("message"):
		anim.stop()
		# Dont work
		if $WriteMessageHitbox.body_exited:
			print("true")
			$Control/WriteMessage_Message.set("visible", true)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_locked = true
			ext_hud_open = true

func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_running_states():
	if  Input.is_action_pressed("running") and is_on_floor() and stamina > 0:
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false

func handle_interactions():
	if Input.is_action_just_pressed("interaction") and not ext_hud_open:
		for body in interaction_hitbox.get_overlapping_bodies():
			if body.has_method("interact"):
				body.interact()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func refresh_hud():
	health_bar.value = health
	stamina_bar.value = stamina

func handle_kick(_damage):
	if Input.is_action_just_pressed("kick") and is_on_floor() and not ext_hud_open:
				if anim.current_animation != "kick_start" or anim.current_animation != "kick_end":
					anim.play("kick_start")
					is_locked = true
					await anim.animation_finished
					for body in kick_hitbox.get_overlapping_bodies():
						if body.has_method("hit"):
							body.hit(_damage)
					anim.play("kick_end")
					await anim.animation_finished
					is_locked = false

@rpc("any_peer", "call_local")
func write_message(text):
	var m = message.instantiate()
	get_tree().get_root().add_child(m)
	m.text = text
	m.global_transform.origin = global_transform.origin
	m.rotation.y = rotation.y

func display_wroten_message(messe):
	$Control/MessageBox.set("visible", true)
	$Control/MessageBox/Label.text = messe

func display_message(messe):
	label.set("visible", true)
	label.text = messe
	await get_tree().create_timer(2).timeout
	label.set("visible", false)

func hide_message():
	$Control/MessageBox.set("visible", false)

func _on_write_message_pressed():
	write_message.rpc($Control/WriteMessage_Message/MessageBox.text)
	$Control/WriteMessage_Message.set("visible", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_locked = false
	ext_hud_open = false

func staminaHandle(delta):
	if running:
		stamina -= delta * stamina_decrease_speed
	else:
		await get_tree().create_timer(3).timeout
		stamina += delta * stamina_regeneration_speed

func hit(_damage):
	health -= _damage
	# Debug string
	# print(player_id + " taken " + str(_damage) + " damage")

func death():
	if health <= 0:
		death_screen.show()
