extends Node2D

const PORT = 28960
const MAX_CLIENTS = 4

var address = ""

@onready var button_click = %ButtonClick
@onready var player_name_input = %PlayerNameInput
@onready var host_button = %HostButton
@onready var join_button = %JoinButton
@onready var hosting_set = %HostingSet
@onready var hosted_set = %HostedSet
@onready var player_list = %PlayerList
@onready var ui = %UI
@onready var start_button = %StartButton

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

# getting things ready for the multiplayer setup
func _ready() -> void:
	GameManager.player_added.connect(_player_added)
	GameManager.player_removed.connect(_player_removed)
	player_name_input.text = names[randi_range(0, names.size() -1)]
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_conntected_to_server)
	multiplayer.connection_failed.connect(_connection_failed)
	
	if OS.get_name() == "Windows":
		address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		address = IP.get_local_addresses()[0]
	else:
		address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			address = ip

# Disconnect and go back to home screen
func _on_back_button_pressed():
	button_click.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

# Host the game
func _on_host_button_pressed():
	button_click.play()
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		print("Cannot connect: " + str(error))
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	_send_player_info(player_name_input.text, index, multiplayer.get_unique_id(), [])
	
	hosting_set.hide()
	hosted_set.show()

# Join the game with the given ip address
func _on_join_button_pressed():
	button_click.play()
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, PORT)
	
	# TODO: Create a loading or connecting sub scene to indicate connecting
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	hosting_set.hide()
	hosted_set.show()

# When player is connected to the Game
func _peer_connected(id):
	print("Player with id %s is connected"%id)
	pass

# When player is disconnected from the Game
func _peer_disconnected(id):
	print("Player with id %s is disconnected"%id)
	GameManager._remove_player(id)

# When player is connected to the host server
func _conntected_to_server():
	print("connected to the server")
	_send_player_info.rpc_id(1, player_name_input.text, index, multiplayer.get_unique_id(), [])

# When player try to connect to host server but is unsuccessfull
func _connection_failed():
	print("Connection failed to server")
	# TODO: show an alert to show the connection failed message
	hosted_set.hide()
	hosting_set.show()

@rpc("any_peer")
func _send_player_info(playername, playerindex, id, cardsInHand):
	if !GameManager.Players.has(id): # TODO: give new name on same name
		GameManager._add_player(playername, playerindex, id, cardsInHand)
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			_send_player_info.rpc(GameManager.Players[i].playername,GameManager.Players[i].playerindex, i, GameManager.Players[i].cardsInHand)

@rpc("any_peer")
func _send_removed_player_info(playerId):
	GameManager._remove_player(playerId)
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			_send_removed_player_info.rpc(i)

@rpc("any_peer", "call_local")
func _start_game():
	var numOfPlayers = GameManager.numOfPlayers
	if(numOfPlayers <= 3):
		var neededNumberOfBots = 4 - numOfPlayers;
		while neededNumberOfBots >= 1:
			var randomId = randi()
			GameManager._add_player("Bot%s"%randomId, 4-neededNumberOfBots, randomId, [], true)
			neededNumberOfBots -= 1
	var scene = load("res://Scenes/Multiplayer_Game_play.tscn").instantiate()
	get_tree().root.add_child(scene)
	ui.hide()
	self.hide()

# Start the game
func _on_start_button_pressed():
	if index > 1:
		_start_game.rpc()
	else:
		print("Atleast 2 players needed to start the multiplayer")

# Add a bot as player
func _on_add_bot_button_pressed():
	button_click.play()
	var botname = "Bot %s"%index
	var botid = randi_range(5, 5000)+index
	_send_player_info.rpc(botname, index, botid, [])
	_player_added(botid, botname, false)

# Remove bot from the game
func _on_bot_pressed(playerId: int):
	button_click.play()
	_send_removed_player_info.rpc(playerId)
	GameManager._remove_player(playerId)

# Add player in the list
func _player_added(id, playername, isLabel = true):
	var playerListTile = player_list_tile.instantiate()
	playerListTile.playername = playername
	playerListTile.isLabel = (isLabel or not multiplayer.is_server())
	playerListTile.id = id
	playerListTile.onPressed.connect(_on_bot_pressed)
	
	player_list.add_child(playerListTile)
	index += 1

# Remove player from the list
func _player_removed(id):
	var toRemoveBot
	for bot in player_list.get_children():
		if bot.id == id:
			toRemoveBot = bot
	
	player_list.remove_child(toRemoveBot)
	index -= 1
