extends Node

var cardsInHand = [];
var id

# Called when the node enters the scene tree for the first time.
func _ready():
	cardsInHand = []

func _remove_cards(toRemoveCards):
	var newCards = []
	for card in cardsInHand:
		if not toRemoveCards.has(card):
			newCards.append(card)
	cardsInHand = newCards

# Add card to player hand and add the card node as player node child
# TODO: name the function _add_cards to _add_card
func _add_cards(cardName):
	cardsInHand.append(cardName)

# Returns the cards in hand array of the player
func _get_cards_in_hand():
	return cardsInHand

# Remove all cards in hand and the player node child list
func _remove_all_cards():
	cardsInHand = []

func _check_jack():
	if cardsInHand.has("card_j_spade") || cardsInHand.has("card_j_diamond") || cardsInHand.has("card_j_heart"):
		return true
	return false

func _shuffle_cards():
	cardsInHand.shuffle()
