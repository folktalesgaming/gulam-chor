extends Node

var pickedCard = null

func _change_picked_card(card):
	pickedCard = card

func _remove_picked_card():
	pickedCard = null
