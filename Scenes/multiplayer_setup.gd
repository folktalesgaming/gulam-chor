extends Node2D

@export var port = 224
@export var address = "127.0.0.1"

@onready var button_click = %ButtonClick
@onready var player_name_input = %PlayerNameInput
@onready var host_button = %HostButton
@onready var join_button = %JoinButton
@onready var hosting_set = %HostingSet
@onready var hosted_set = %HostedSet
@onready var add_bot_button = %AddBotButton
@onready var player_list = %PlayerList

@onready var player_list_tile = preload("res://Prefabs/player_list_tile.tscn")

var names = [
	"Little Rock",
	"High Land",
	"Long Band",
	"Free Water",
	"Tough Bin"
]
var index = 0
var peer

func _ready():
	GameMaganer.player_added.connect(_player_added)
	GameMaganer.player_removed.connect(_player_removed)
	player_name_input.text = names[randi_range(0, names.size() -1)]
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_conntected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)

func _on_back_button_pressed():
	button_click.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# Go to host screen
func _on_host_button_pressed():
	button_click.play()
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 4)
	
	if error != OK:
		print("Cannot connect: " + str(error))
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	_send_player_info(player_name_input.text, index, multiplayer.get_unique_id(), [])
	
	hosting_set.hide()
	hosted_set.show()

# Go to join screen
func _on_join_button_pressed():
	button_click.play()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	hosting_set.hide()
	add_bot_button.hide()
	hosted_set.show()

func _peer_connected(id):
	print("Player with id %s is connected"%id)
	pass
	
func _peer_disconnected(id):
	print("Player with id %s is disconnected"%id)
	GameMaganer._remove_player(id)

func _conntected_to_server():
	_send_player_info.rpc_id(1, player_name_input.text, index, multiplayer.get_unique_id(), [])
	pass
	
func _connection_failed():
	print("Connection failed to server")
	pass

@rpc("any_peer")
func _send_player_info(playername, playerindex, id, cardsInHand):
	if !GameMaganer.Players.has(id): # TODO: give new name on same name
		GameMaganer._add_player(playername, playerindex, id, cardsInHand)
		
	if multiplayer.is_server():
		for i in GameMaganer.Players:
			_send_player_info.rpc(GameMaganer.Players[i].playername,GameMaganer.Players[i].playerindex, i, GameMaganer.Players[i].cardsInHand)

@rpc("any_peer")
func _send_removed_player_info(playerId):
	GameMaganer._remove_player(playerId)
	
	if multiplayer.is_server():
		for i in GameMaganer.Players:
			_send_removed_player_info.rpc(i)

# Start the game
func _on_start_button_pressed():
	pass

func _on_add_bot_button_pressed():
	button_click.play()
	var botname = "Bot %s"%index
	var botid = randi_range(5, 5000)+index
	_send_player_info.rpc(botname, index, botid, [])
	_player_added(botid, botname, false)
	
	if index > 3:
		add_bot_button.hide()

func _on_bot_pressed(playerId: int):
	button_click.play()
	_send_removed_player_info.rpc(playerId)
	GameMaganer._remove_player(playerId)

func _player_added(id, playername, isLabel = true):
	var playerListTile = player_list_tile.instantiate()
	playerListTile.playername = playername
	playerListTile.isLabel = (isLabel or not multiplayer.is_server())
	playerListTile.id = id
	playerListTile.onPressed.connect(_on_bot_pressed)
	
	player_list.add_child(playerListTile)
	index += 1

func _player_removed(id):
	var toRemoveBot
	for bot in player_list.get_children():
		if bot.id == id:
			toRemoveBot = bot
	
	player_list.remove_child(toRemoveBot)
	index -= 1
	if multiplayer.is_server():
		add_bot_button.show()
