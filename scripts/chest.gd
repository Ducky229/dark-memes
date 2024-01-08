extends Node3D

@onready var animation = $blockbench_export/AnimationPlayer
@onready var audio = $blockbench_export/AudioStreamPlayer3D
const CHEST_CLOSING = preload("res://assets/audio/chest/Chest_closing.wav")
const CHEST_OPEN = preload("res://assets/audio/chest/Chest_open.wav")
var Is_open = false
signal toggleItem

# Called when the node enters the scene tree for the first time.


func interact():
	#if !animation.is_playing():
		#Is_open = !Is_open
		#if Is_open:
			#open()
		#else:
			#close()
	
	if !Is_open:
		open()
		Is_open = true
	

func open():
	animation.play("open")
	audio.stream = CHEST_OPEN
	audio.play()
	$Greatsword_item/GPUParticles3D.set("emitting", true)
	
func close():
	animation.play("closed")
	audio.stream = CHEST_CLOSING
	audio.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_animation_player_animation_finished(_anim_name):
	emit_signal("toggleItem")
