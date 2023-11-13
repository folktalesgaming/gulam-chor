extends Node

signal player_added(id, playername)
signal player_removed(id)

var Players = {}

func _add_player(playername, playerindex, id, cardsInHand):
	Players[id] = {
		"playername" : playername,
		"playerindex" : playerindex,
		"id": id,
		"cardsInHand": cardsInHand
	}
	player_added.emit(id, playername)

func _remove_player(playerid):
	Players.erase(playerid)
	player_removed.emit(playerid)
