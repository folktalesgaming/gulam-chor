extends Node2D

const CardBase = preload("res://Prefabs/Card/Card.tscn")
const DeckOfCard = preload("res://Utils/deck_of_cards_classic.gd")

@onready var CenterCardOval = ProjectSettings.get_setting("display/window/size/viewport_width") * Vector2(0.6, 1)
@onready var Horizontal_radius = get_viewport().size.x * 0.45
@onready var Vertical_radius = get_viewport().size.y * 0.4
var angle = deg_to_rad(90) - 0.5
var OvalAngleVector = Vector2()

func _ready():
	for card in DeckOfCard.deck:
		var new_card = CardBase.instantiate()
		new_card.cardName = card
		OvalAngleVector = Vector2(Horizontal_radius * cos(angle), - Vertical_radius * sin(angle))
		new_card.position = CenterCardOval + OvalAngleVector - new_card.size/2
		new_card.rotation = (90 - rad_to_deg(angle))/4
		$PlayerCards.add_child(new_card)
		angle += 0.25
