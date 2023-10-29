static func getHappyEmote():
	var emotes = [
		"faceHappy",
		"heart",
		"hearts",
		"laugh",
		"music",
		"star",
	]
	var rng = RandomNumberGenerator.new()
	
	return emotes[rng.randi_range(0, emotes.size()-1)]

static func getSadEmote():
	var emotes = [
		"anger",
		"faceAngry",
		"faceSad",
		"heartBroken",
	]
	var rng = RandomNumberGenerator.new()
	
	return emotes[rng.randi_range(0, emotes.size()-1)]

static func getNeutralEmote():
	var emotes = [
		"alert",
		"dots1",
		"dots2",
		"dots3",
		"exclamation",
		"exclamations",
	]
	var rng = RandomNumberGenerator.new()
	
	return emotes[rng.randi_range(0, emotes.size()-1)]
