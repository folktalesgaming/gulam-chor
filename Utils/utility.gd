static func shuffleDeck(deck):
	randomize()
	deck.shuffle()
	return deck

static func findPairs(inHandCards):
	var cards = getCardNumbers(inHandCards)
	var nonPairCardsIndices = []
	var pairCardsIndices = []
	var nonPairCards = []
	var pairCards = []
	var index = 0
	
	for card in cards:
		if not nonPairCards.has(card):
			nonPairCards.append(card)
			nonPairCardsIndices.append(index)
		else:
			pairCards.append(card)
			pairCardsIndices.append(index)
			var prevIndex = nonPairCards.find(card)
			pairCards.append(nonPairCards[prevIndex])
			pairCardsIndices.append(nonPairCardsIndices[prevIndex])
			nonPairCards.pop_at(prevIndex)
			nonPairCardsIndices.pop_at(prevIndex)
		index += 1
	
	index = 0
	for i in nonPairCardsIndices:
		nonPairCards[index] = inHandCards[i]
		index += 1
	
	index = 0
	for i in pairCardsIndices:
		pairCards[index] = inHandCards[i]
		index += 1
	
	return {
		"pairCards": pairCards,
		"nonPairCards": nonPairCards
	}

static func getCardNumbers(cards):
	var numbers = []
	for card in cards:
		numbers.append(card.split("_")[1])
	
	return numbers
