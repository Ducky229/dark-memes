extends Node3D

@export var pickup_enabled = false

signal Greatsword_pickup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func interact():
	if pickup_enabled:
		emit_signal("Greatsword_pickup")
		queue_free()

func _on_static_body_3d_toggle_item():
	pickup_enabled = true
