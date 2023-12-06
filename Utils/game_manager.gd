extends Node

signal player_added(id, playername)
signal player_removed(id)

var Players = {}
var numOfPlayers = 0

# add player or bot to the game
func _add_player(playername: String, playerindex: int, id: int, cardsInHand: Array, isBot: bool = false) -> void:
	Players[id] = {
		"playername" : playername,
		"playerindex" : playerindex,
		"id": id,
		"cardsInHand": cardsInHand,
		"isBot": isBot,
	}
	numOfPlayers += 1
	player_added.emit(id, playername)

# remove player from the game
func _remove_player(playerid: int) -> void:
	Players.erase(playerid)
	player_removed.emit(playerid)
