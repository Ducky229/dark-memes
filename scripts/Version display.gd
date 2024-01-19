extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var contained_text : String = "TEST"
	
	contained_text = "game version: " + ProjectSettings.get_setting("application/config/version") + ' ' + ProjectSettings.get_setting("application/config/description")
	
	$MarginContainer/Label.text = contained_text
