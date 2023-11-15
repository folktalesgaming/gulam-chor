static func getDeckAllRandomMode():
	var deck = [
		"card_a_spade",
		"card_a_diamond",
		"card_a_heart",
		"card_a_club",
		
		"card_2_spade",
		"card_2_diamond",
		"card_2_heart",
		"card_2_club",
		
		"card_3_spade",
		"card_3_diamond",
		"card_3_heart",
		"card_3_club",
		
		"card_4_spade",
		"card_4_diamond",
		"card_4_heart",
		"card_4_club",
		
		"card_5_spade",
		"card_5_diamond",
		"card_5_heart",
		"card_5_club",
		
		"card_6_spade",
		"card_6_diamond",
		"card_6_heart",
		"card_6_club",
		
		"card_7_spade",
		"card_7_diamond",
		"card_7_heart",
		"card_7_club",
		
		"card_8_spade",
		"card_8_diamond",
		"card_8_heart",
		"card_8_club",
		
		"card_9_spade",
		"card_9_diamond",
		"card_9_heart",
		"card_9_club",
		
		"card_10_spade",
		"card_10_diamond",
		"card_10_heart",
		"card_10_club",
		
		"card_j_spade",
		"card_j_club",
		"card_j_diamond",
		"card_j_heart",
		
		"card_q_spade",
		"card_q_diamond",
		"card_q_heart",
		"card_q_club",
		
		"card_k_spade",
		"card_k_diamond",
		"card_k_heart",
		"card_k_club",
	]
	
	deck.remove_at(randi_range(0, deck.size() - 1))
	
	return deck
