extends CharacterBody3D


const SPEED = 2.5
@onready var findPlayer = $Area3D
@export var health = 100
@onready var animation_player = $AnimationPlayer
@onready var hitbox = $Area3D2


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@rpc("any_peer", "call_local")
func hit(_damage):
	health -= _damage

var playing = true

func death():
	if health <= 0:
		queue_free()

func attac(_damage, distance):
	if distance <= 1.5 and playing and (animation_player.current_animation != "attack"  or animation_player.current_animation != "back"):
					animation_player.play("attack")
					animation_player.queue("back")
					playing = false
					await get_tree().create_timer(2.0).timeout
					playing = true
					for body in hitbox.get_overlapping_bodies():
						if body.has_method("hit"):
							body.hit.rpc(_damage)

func _physics_process(delta):
	# Add the gravity.
	death()
	for body in findPlayer.get_overlapping_bodies():
			if body.is_in_group("player"):
				look_at(body.global_transform.origin, Vector3.UP)
				var direction := global_transform.origin.direction_to(body.global_transform.origin)
				velocity.z = direction.z * SPEED
				velocity.x = direction.x * SPEED
				var distance := global_transform.origin.distance_to(body.global_transform.origin)
				attac(25, distance)
	rotation.x = 0
	rotation.z = 0
	move_and_slide()
