extends TextureButton

signal onPressed(id: int)

@onready var player_name = %PlayerName
@onready var label = %label

var playername: String = "Add Bot"
var isLabel: bool = true
var id: int

# Called when the node enters the scene tree for the first time.
func _ready():
	player_name.text = playername
	if isLabel:
		label.texture = load("res://Assets/UI/player_list_label.png")
		self.disabled = true
	else:
		label.texture = load("res://Assets/UI/slider_knob.png")

func _on_pressed():
	onPressed.emit(id)
