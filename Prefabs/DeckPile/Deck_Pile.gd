extends Node2D

var cardsInPile = 0

func _ready():
	cardsInPile = 0

# Throwing pair cards
func _add_to_pile():
	#for card in card_pairs:
		#self.add_child(card)
	cardsInPile += 2

# Resetting / Picking back cards
func _pick_back_cards():
	for card in self.get_children():
		card.queue_free()
	cardsInPile = 0
