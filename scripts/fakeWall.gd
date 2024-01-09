extends StaticBody3D

@export var particles = preload("res://scenes/particles/black ashes.tscn")

@rpc("any_peer", "call_local")
func hit(_damage):
	FastMethods.spawnParticles(particles, $".".global_transform.origin)
	queue_free()
