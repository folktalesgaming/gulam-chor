extends Node

var cardsInHand = [];

# Called when the node enters the scene tree for the first time.
func _ready():
	cardsInHand = []

func AddCardInHand(toAddCard):
	cardsInHand.append(toAddCard)

func SetNewSetOfCards(newCards):
	cardsInHand = newCards