static func shuffleDeck(deck):
	randomize()
	deck.shuffle()
	return deck

static func removePairs(inHandCards):
	var cards = getCardNumbers(inHandCards)
	var newInHandCards = []
	var afterRemoveCards = []
	var i = 0
	
	for card in cards:
		if not afterRemoveCards.has(card):
			afterRemoveCards.append(card)
			newInHandCards.append(inHandCards[i])
		else:
			var previousCardIndex = afterRemoveCards.find(card)
			afterRemoveCards.pop_at(previousCardIndex)
			newInHandCards.pop_at(previousCardIndex)
			
		i += 1
		
	return newInHandCards
	
static func getCardNumbers(cards):
	var numbers = []
	for card in cards:
		numbers.append(card.split("_")[1])
	
	return numbers
