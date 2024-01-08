extends StaticBody3D
const WALL_DISAPPEAR_PARTICLES = preload("res://scenes/wall_disappear_particles.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func spawn_particles(particles, location):
	var p = particles.instantiate()
	get_tree().get_root().add_child(p)
	p.global_transform.origin = location.global_transform.origin
func hit():
	spawn_particles(WALL_DISAPPEAR_PARTICLES, $".")
	queue_free()

