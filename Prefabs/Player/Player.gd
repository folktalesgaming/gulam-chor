extends Node

var cardsInHand = [];
var id

# Called when the node enters the scene tree for the first time.
func _ready():
	cardsInHand = []

func AddCardInHand(toAddCard):
	cardsInHand.append(toAddCard)

func SetNewSetOfCards(newCards):
	cardsInHand = newCards

func RemoveCardsFromHand(toRemoveCards):
	var newCards = []
	for card in cardsInHand:
		if not toRemoveCards.has(card):
			newCards.append(card)
	SetNewSetOfCards(newCards)

func RemoveAllCards():
	cardsInHand = []
