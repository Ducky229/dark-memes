extends Node3D

signal receve_message(message)
@export var text = "Replace this"
var player
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func interact():
	for body in $Area3D.get_overlapping_bodies():
			if body.has_method("display_message"):
				body.display_wroten_message(text)
				player = body
func _process(_delta):
	if player != null:
		if position.distance_to(player.position) > 1:
			player.hide_message()
			player = null
