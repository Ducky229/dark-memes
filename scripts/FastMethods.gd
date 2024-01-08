extends Node

func playAudio(sound : String = "res://assets/audio/chest/Chest_closing.wav", location : Vector3 = Vector3.ZERO):
	var audioPlayer = AudioStreamPlayer3D.new()
	audioPlayer.global_position = location
	audioPlayer.stream = sound
	audioPlayer.play()
	audioPlayer.queue_free()

func spawnParticles(particles : PackedScene, location : Vector3):
	var p = particles.instantiate()
	get_tree().get_root().add_child(p)
	p.global_transform.origin = location
