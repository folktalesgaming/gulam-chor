extends Node2D

var save_path = ("user://setting.save")
var random_mode_setting_path = ("user://random-mode-setting.save")
var bgVolume = 100
var sfxVolume = 0
var isRandomMode = false

@onready var ButtonClickSound = %ButtonClick
@onready var BgSlider = %BgMusicSlider
@onready var SfxSlider = %SfxSlider
@onready var random_mode_checkbox = %RandomModeCheckbox

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_data()
	_load_random_mode_data()

func _on_back_button_pressed():
	ButtonClickSound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func save():
	ButtonClickSound.play()
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(bgVolume)
	file.store_var(sfxVolume)
	file.store_var(isRandomMode)
	_save_random_mode_setting()

func _load_random_mode_data():
	if FileAccess.file_exists(random_mode_setting_path):
		var file = FileAccess.open(random_mode_setting_path, FileAccess.READ)
		var fileData = file.get_8()
		if fileData == 1:
			isRandomMode = true
		else:
			isRandomMode = false
	else:
		isRandomMode = false
	random_mode_checkbox.button_pressed = isRandomMode

func _save_random_mode_setting():
	var file = FileAccess.open(random_mode_setting_path, FileAccess.WRITE)
	var isRandom = 0
	if isRandomMode:
		isRandom = 1
	file.store_8(isRandom)

func _load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		bgVolume = file.get_var(bgVolume)
		BgSlider.value = bgVolume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), bgVolume)
		sfxVolume = file.get_var(sfxVolume)
		SfxSlider.value = sfxVolume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfxVolume)
	else:
		bgVolume = 100
		sfxVolume = 0

func _on_sfx_slider_value_changed(value):
	sfxVolume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

func _on_bg_music_slider_value_changed(value):
	bgVolume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), bgVolume)

func _on_random_mode_checkbox_toggled(button_pressed):
	isRandomMode = button_pressed
