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
	#if showCard:
		#new_to_add_card.SetCardVisible()
	
	#add_child(new_to_add_card)
	cardsInHand.append(cardName)
	
	await get_tree().create_timer(0.6).timeout
	#rearrangeCards(node, nodeIndex)

# Remove cards from the player hand and the player node child list
#func _remove_cards(toRemoveCards):
	#_remove_cards_in_hand(toRemoveCards)
	#for card in self.get_children():
		#if toRemoveCards.has(card.cardName):
			#card.queue_free()
	
	#await get_tree().create_timer(0.6).timeout
	#rearrangeCards(node, nodeIndex)

# Returns the cards in hand array of the player
func _get_cards_in_hand():
	return cardsInHand

# Remove all cards in hand and the player node child list
func _remove_all_cards():
	#for card in self.get_children():
		#card.queue_free()
	cardsInHand = []

func _check_jack():
	if cardsInHand.has("card_j_spade") || cardsInHand.has("card_j_diamond") || cardsInHand.has("card_j_heart"):
		return true
	return false
