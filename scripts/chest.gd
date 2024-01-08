extends Node3D

@onready var animation = $chestModel/AnimationPlayer
@onready var audio = $AudioStreamPlayer3D
@onready var item_particles = $Item/ItemParticles
@onready var item = $Item
@export var Chest_open_sound = preload("res://assets/audio/chest/Chest_open.wav")
var Is_open = false

func interact():
	if !Is_open and animation.current_animation != "open":
		animation.play("open")
		FastMethods.playAudio(Chest_open_sound)
		item_particles.set("emitting", true)
		await animation.animation_finished
		item.set("pickup_enabled", true)
		Is_open = true
	
