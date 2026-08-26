extends Node

signal match_time_updated(time_left: float, phase: int)
signal elixir_updated(team: int, elixir: float)
signal hand_updated(team: int, hand: Array, next_card: String)
signal crowns_updated(t1_crowns: int, t2_crowns: int)
signal game_over_signal(winner_team: int, t1_crowns: int, t2_crowns: int)
signal banner_message(msg: String)

enum MatchPhase {
	NORMAL,
	DOUBLE_ELIXIR,
	SUDDEN_DEATH,
	GAME_OVER
}

const NORMAL_TIME: float = 180.0 # 3 mins
const DOUBLE_ELIXIR_TIME: float = 60.0 # Last 1 min
const OVERTIME_TIME: float = 60.0

var match_phase: MatchPhase = MatchPhase.NORMAL
var match_timer: float = NORMAL_TIME

var team1_elixir: float = 5.0
var team2_elixir: float = 5.0
const MAX_ELIXIR: float = 10.0

# Deck and hand data
var team1_hand: Array[String] = []
var team1_next: String = ""
var team1_queue: Array[String] = []

var team2_hand: Array[String] = []
var team2_next: String = ""
var team2_queue: Array[String] = []

var team1_crowns: int = 0
var team2_crowns: int = 0
var is_game_over: bool = false

var bot_ai: Node = null
var net_sync_accum: float = 0.0

@onready var arena: Node2D = get_parent().get_node_or_null("Arena")

func _ready() -> void:
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		_init_player_decks()
		if NetworkManager.is_multiplayer_game and multiplayer.has_multiplayer_peer():
			rpc("sync_initial_state", team1_hand, team1_next, team1_queue, team2_hand, team2_next, team2_queue, team1_elixir, team2_elixir)
	else:
		if multiplayer.has_multiplayer_peer():
			rpc_id(1, "request_sync_state")
		
	if NetworkManager.is_bot_mode:
		bot_ai = preload("res://scripts/gameplay/BotAI.gd").new()
		add_child(bot_ai)
		bot_ai.setup(self)

func _init_player_decks() -> void:
	var starter_1 = CardDatabase.get_starter_deck()
	starter_1.shuffle()
	team1_hand = [starter_1[0], starter_1[1], starter_1[2], starter_1[3]]
	team1_next = starter_1[4]
	team1_queue = [starter_1[5], starter_1[6], starter_1[7]]

	var starter_2 = CardDatabase.get_starter_deck()
	starter_2.shuffle()
	team2_hand = [starter_2[0], starter_2[1], starter_2[2], starter_2[3]]
	team2_next = starter_2[4]
	team2_queue = [starter_2[5], starter_2[6], starter_2[7]]

	hand_updated.emit(1, team1_hand, team1_next)
	hand_updated.emit(2, team2_hand, team2_next)

func get_hand_for_team(team: int) -> Array[String]:
	return team1_hand if team == 1 else team2_hand

func get_next_for_team(team: int) -> String:
	return team1_next if team == 1 else team2_next

func get_elixir_for_team(team: int) -> float:
	return team1_elixir if team == 1 else team2_elixir

func _process(delta: float) -> void:
	if is_game_over:
		return
		
	# Authoritative server clock & elixir processing
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		_process_clock(delta)
		_process_elixir(delta)

func _physics_process(delta: float) -> void:
	if is_game_over:
		return
		
	# Periodic World Snapshot Sync from Host to Client (20 Hz)
	if NetworkManager.is_host and NetworkManager.is_multiplayer_game:
		net_sync_accum += delta
		if net_sync_accum >= 0.05:
			net_sync_accum = 0.0
			if multiplayer.has_multiplayer_peer() and arena:
				var snapshot = arena.get_world_snapshot()
				rpc("sync_world_state", snapshot)

func _process_clock(delta: float) -> void:
	match_timer -= delta
	
	if match_phase == MatchPhase.NORMAL and match_timer <= DOUBLE_ELIXIR_TIME:
		match_phase = MatchPhase.DOUBLE_ELIXIR
		banner_message.emit("2X ELIXIR!")
		if multiplayer.has_multiplayer_peer():
			rpc("sync_banner", "2X ELIXIR!")
		SoundManager.play_sfx("tower_alarm", 1.0)
		
	if match_timer <= 0.0:
		if match_phase == MatchPhase.DOUBLE_ELIXIR or match_phase == MatchPhase.NORMAL:
			if team1_crowns == team2_crowns:
				match_phase = MatchPhase.SUDDEN_DEATH
				match_timer = OVERTIME_TIME
				banner_message.emit("SUDDEN DEATH! 3X ELIXIR")
				if multiplayer.has_multiplayer_peer():
					rpc("sync_banner", "SUDDEN DEATH! 3X ELIXIR")
				SoundManager.play_sfx("tower_alarm", 3.0)
			else:
				var winner = 1 if team1_crowns > team2_crowns else 2
				_end_game(winner)
				return
		elif match_phase == MatchPhase.SUDDEN_DEATH:
			var winner = 0
			if team1_crowns != team2_crowns:
				winner = 1 if team1_crowns > team2_crowns else 2
			_end_game(winner)
			return
			
	match_time_updated.emit(match_timer, int(match_phase))
	if multiplayer.has_multiplayer_peer():
		rpc("sync_clock", match_timer, int(match_phase))

func _process_elixir(delta: float) -> void:
	var rate: float = 1.0 / 2.8
	if match_phase == MatchPhase.DOUBLE_ELIXIR:
		rate = 1.0 / 1.4
	elif match_phase == MatchPhase.SUDDEN_DEATH:
		rate = 1.0 / 0.9
		
	team1_elixir = min(MAX_ELIXIR, team1_elixir + rate * delta)
	team2_elixir = min(MAX_ELIXIR, team2_elixir + rate * delta)
	
	elixir_updated.emit(1, team1_elixir)
	elixir_updated.emit(2, team2_elixir)
	if multiplayer.has_multiplayer_peer():
		rpc("sync_elixir", team1_elixir, team2_elixir)

# --- CARD PLAYING LOGIC ---

func try_play_card_local(card_id: String, local_target_pos: Vector2) -> bool:
	var my_team = NetworkManager.local_team
	var canonical_pos = arena.local_to_canonical(local_target_pos) if arena else local_target_pos
	
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		return _server_execute_play_card(my_team, card_id, canonical_pos)
	else:
		if multiplayer.has_multiplayer_peer():
			rpc_id(1, "request_play_card", card_id, canonical_pos.x, canonical_pos.y)
		return true

@rpc("any_peer", "reliable")
func request_sync_state() -> void:
	if NetworkManager.is_host and multiplayer.has_multiplayer_peer():
		var sender_id = multiplayer.get_remote_sender_id()
		rpc_id(sender_id, "sync_initial_state", team1_hand, team1_next, team1_queue, team2_hand, team2_next, team2_queue, team1_elixir, team2_elixir)

@rpc("authority", "reliable")
func sync_initial_state(t1_h: Array, t1_n: String, t1_q: Array, t2_h: Array, t2_n: String, t2_q: Array, e1: float, e2: float) -> void:
	team1_hand.assign(t1_h)
	team1_next = t1_n
	team1_queue.assign(t1_q)
	
	team2_hand.assign(t2_h)
	team2_next = t2_n
	team2_queue.assign(t2_q)
	
	team1_elixir = e1
	team2_elixir = e2
	
	hand_updated.emit(1, team1_hand, team1_next)
	hand_updated.emit(2, team2_hand, team2_next)
	elixir_updated.emit(1, team1_elixir)
	elixir_updated.emit(2, team2_elixir)

@rpc("any_peer", "reliable")
func request_play_card(card_id: String, canonical_x: float, canonical_y: float) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	var team = 2 if sender_id != 1 else 1
	_server_execute_play_card(team, card_id, Vector2(canonical_x, canonical_y))

func _server_execute_play_card(team: int, card_id: String, canonical_pos: Vector2) -> bool:
	if is_game_over:
		return false
		
	var card_data = CardDatabase.get_card(card_id)
	if card_data.is_empty():
		return false
		
	var cost = card_data.get("cost", 3)
	var current_elixir = team1_elixir if team == 1 else team2_elixir
	
	if current_elixir < cost:
		return false
		
	var is_spell = card_data.get("is_spell", false)
	if arena and not arena.is_valid_canonical_deployment(canonical_pos, team, is_spell):
		return false
		
	if team == 1:
		team1_elixir -= cost
	else:
		team2_elixir -= cost
		
	_cycle_hand(team, card_id)
	
	if arena:
		arena.spawn_card(card_id, team, canonical_pos)
		
	var hand = team1_hand if team == 1 else team2_hand
	var next_card = team1_next if team == 1 else team2_next
	if multiplayer.has_multiplayer_peer():
		rpc("sync_card_played", team, card_id, canonical_pos.x, canonical_pos.y, team1_elixir if team == 1 else team2_elixir, hand, next_card)
	
	return true

func _cycle_hand(team: int, played_card_id: String) -> void:
	var hand = team1_hand if team == 1 else team2_hand
	var queue = team1_queue if team == 1 else team2_queue
	var next_card = team1_next if team == 1 else team2_next
	
	var idx = hand.find(played_card_id)
	if idx != -1:
		hand[idx] = next_card
		var incoming = queue.pop_front()
		queue.append(played_card_id)
		if team == 1:
			team1_next = incoming
		else:
			team2_next = incoming
	else:
		if hand.size() > 0:
			hand[0] = next_card
			var incoming = queue.pop_front()
			queue.append(played_card_id)
			if team == 1:
				team1_next = incoming
			else:
				team2_next = incoming
			
	hand_updated.emit(team, hand, team1_next if team == 1 else team2_next)

# --- CROWN / TOWER RESOLUTION ---

func on_tower_destroyed(destroyed_team: int, tower_type: String) -> void:
	var awarding_team = 2 if destroyed_team == 1 else 1
	
	if tower_type == "king":
		if awarding_team == 1:
			team1_crowns = 3
		else:
			team2_crowns = 3
		_end_game(awarding_team)
	else:
		if awarding_team == 1:
			team1_crowns += 1
		else:
			team2_crowns += 1
			
		crowns_updated.emit(team1_crowns, team2_crowns)
		if multiplayer.has_multiplayer_peer():
			rpc("sync_crowns", team1_crowns, team2_crowns)
		
		if match_phase == MatchPhase.SUDDEN_DEATH:
			_end_game(awarding_team)

func _end_game(winner_team: int) -> void:
	if is_game_over:
		return
	is_game_over = true
	match_phase = MatchPhase.GAME_OVER
	
	crowns_updated.emit(team1_crowns, team2_crowns)
	game_over_signal.emit(winner_team, team1_crowns, team2_crowns)
	if multiplayer.has_multiplayer_peer():
		rpc("sync_game_over", winner_team, team1_crowns, team2_crowns)

# --- SYNCHRONIZATION RPCS ---

@rpc("authority", "unreliable")
func sync_world_state(snapshot: Dictionary) -> void:
	if not NetworkManager.is_host and arena:
		arena.apply_world_snapshot(snapshot)

@rpc("authority", "reliable")
func sync_spawn_projectile(p_type: String, fx: float, fy: float, tx: float, ty: float, dmg: float, team: int, splash: float) -> void:
	if not NetworkManager.is_host and arena:
		var l_from = arena.canonical_to_local(Vector2(fx, fy))
		var l_to = arena.canonical_to_local(Vector2(tx, ty))
		arena.client_spawn_visual_projectile(p_type, l_from, l_to, dmg, team, splash)

@rpc("authority", "reliable")
func sync_spawn_spell(spell_id: String, team: int, cx: float, cy: float, dmg: float, radius: float, crown_mult: float) -> void:
	if not NetworkManager.is_host and arena:
		var l_pos = arena.canonical_to_local(Vector2(cx, cy))
		arena.client_spawn_visual_spell(spell_id, team, l_pos, dmg, radius, crown_mult)

@rpc("authority", "unreliable")
func sync_clock(time_left: float, phase_idx: int) -> void:
	match_timer = time_left
	match_phase = phase_idx as MatchPhase
	match_time_updated.emit(match_timer, phase_idx)

@rpc("authority", "unreliable")
func sync_elixir(e1: float, e2: float) -> void:
	team1_elixir = e1
	team2_elixir = e2
	elixir_updated.emit(1, team1_elixir)
	elixir_updated.emit(2, team2_elixir)

@rpc("authority", "reliable")
func sync_banner(msg: String) -> void:
	banner_message.emit(msg)

@rpc("authority", "reliable")
func sync_crowns(c1: int, c2: int) -> void:
	team1_crowns = c1
	team2_crowns = c2
	crowns_updated.emit(c1, c2)

@rpc("authority", "reliable")
func sync_card_played(team: int, _card_id: String, _x: float, _y: float, _remaining_elixir: float, new_hand: Array, new_next: String) -> void:
	if not NetworkManager.is_host:
		if team == 2:
			team2_hand.assign(new_hand)
			team2_next = new_next
			hand_updated.emit(2, team2_hand, team2_next)
		elif team == 1:
			team1_hand.assign(new_hand)
			team1_next = new_next
			hand_updated.emit(1, team1_hand, team1_next)

@rpc("authority", "reliable")
func sync_game_over(winner_team: int, c1: int, c2: int) -> void:
	is_game_over = true
	team1_crowns = c1
	team2_crowns = c2
	crowns_updated.emit(c1, c2)
	game_over_signal.emit(winner_team, c1, c2)
