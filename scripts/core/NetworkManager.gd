extends Node

signal connection_succeeded
signal connection_failed_signal(reason: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal match_started

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 2

var peer: ENetMultiplayerPeer = null
var is_multiplayer_game: bool = false
var is_host: bool = false
var is_bot_mode: bool = false
var local_team: int = 1 # 1 = Blue (Host), 2 = Red (Client/Bot)
var opponent_connected: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- HOSTING ---

func host_game(port: int = DEFAULT_PORT) -> Error:
	close_network()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		print("Failed to host on port ", port, " Error: ", err)
		return err
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer_game = true
	is_host = true
	is_bot_mode = false
	local_team = 1 # Host is always Blue (Team 1)
	opponent_connected = false
	print("Server hosted on port ", port, ". Waiting for opponent...")
	return OK

# --- JOINING ---

func join_game(ip: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	close_network()
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		print("Failed to connect to ", ip, ":", port, " Error: ", err)
		return err
	
	multiplayer.multiplayer_peer = peer
	is_multiplayer_game = true
	is_host = false
	is_bot_mode = false
	local_team = 2 # Client is always Red (Team 2)
	opponent_connected = false
	print("Connecting to ", ip, ":", port, "...")
	return OK

# --- BOT / SOLO MODE ---

func start_bot_mode() -> void:
	close_network()
	is_multiplayer_game = false
	is_host = true
	is_bot_mode = true
	local_team = 1
	opponent_connected = true
	get_tree().change_scene_to_file("res://scenes/game_arena.tscn")

# --- CLEANUP ---

func close_network() -> void:
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	is_multiplayer_game = false
	is_host = false
	is_bot_mode = false
	opponent_connected = false

# --- NETWORK CALLBACKS ---

func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	opponent_connected = true
	peer_joined.emit(peer_id)
	
	if is_host and is_multiplayer_game:
		# Host starts match for both peers
		print("Opponent joined! Launching match...")
		rpc("sync_start_match")
		get_tree().change_scene_to_file("res://scenes/game_arena.tscn")

func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	opponent_connected = false
	peer_left.emit(peer_id)

func _on_connected_to_server() -> void:
	print("Connected to host server successfully!")
	opponent_connected = true
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	print("Failed to connect to server.")
	connection_failed_signal.emit("Could not connect to host.")
	close_network()

func _on_server_disconnected() -> void:
	print("Host server disconnected.")
	peer_left.emit(1)
	close_network()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

@rpc("authority", "reliable")
func sync_start_match() -> void:
	if not is_host:
		print("Received start match signal from host!")
		get_tree().change_scene_to_file("res://scenes/game_arena.tscn")
	match_started.emit()
