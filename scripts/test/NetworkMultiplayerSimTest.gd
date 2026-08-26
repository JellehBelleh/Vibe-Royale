extends Node

func _ready() -> void:
	print("\n--- Running Network Multiplayer Handshake, Flip & State Sync Test ---")
	
	# Host setup
	var host_err = NetworkManager.host_game(7795)
	assert(host_err == OK, "Host creation failed")
	print("  ✓ Host server created on port 7795")
	
	var arena_scene = load("res://scenes/game_arena.tscn").instantiate()
	add_child(arena_scene)
	
	var mm = arena_scene.get_node("MatchManager")
	var bhud = arena_scene.get_node("BattleHUD")
	var arena = arena_scene.get_node("Arena")
	
	# Test Player 2 coordinate mapping
	NetworkManager.local_team = 2
	var local_click = Vector2(50, 150) # Bottom right on Player 2 screen
	var can_pos = arena.local_to_canonical(local_click)
	assert(can_pos == Vector2(-50, -150), "Local to canonical failed for team 2")
	var back_local = arena.canonical_to_local(can_pos)
	assert(back_local == local_click, "Canonical to local failed for team 2")
	print("  ✓ Player 2 symmetric coordinate transformation verified: ", local_click, " -> ", can_pos)
	
	# Test deployment validation
	var valid_p2 = arena.is_valid_deployment(local_click, 2, false)
	assert(valid_p2 == true, "Player 2 local deployment should be valid in bottom territory")
	var can_valid = arena.is_valid_canonical_deployment(can_pos, 2, false)
	assert(can_valid == true, "Server canonical deployment should be valid for Team 2")
	print("  ✓ Player 2 bottom territory deployment validation verified!")
	
	# Reset local_team to 1 for host simulation
	NetworkManager.local_team = 1
	
	# Spawn a team 2 unit via canonical pos
	arena.spawn_card("knight", 2, can_pos)
	assert(arena.units_team2.size() >= 1, "Team 2 unit not spawned")
	var unit = arena.units_team2[0]
	var start_y = unit.global_position.y
	print("  ✓ Unit spawned at canonical pos: ", unit.global_position)
	
	# Simulate 10 frames on server
	for i in range(10):
		unit._process_unit_ai(0.1)
		
	var moved_y = unit.global_position.y
	assert(moved_y > start_y, "Team 2 unit should move downwards towards Blue base on server")
	print("  ✓ Unit moved on server from Y=", start_y, " to Y=", moved_y)
	
	# Test snapshot generation and client application
	var snapshot = arena.get_world_snapshot()
	assert(snapshot["units"].size() >= 1, "Snapshot has no units")
	print("  ✓ World snapshot generated with ", snapshot["units"].size(), " units")
	
	# --- Test Multiplayer Custom Deck Synchronization ---
	print("\n--- Testing Multiplayer Custom Deck Synchronization ---")
	var host_custom_deck: Array[String] = ["knight", "archers", "giant", "musketeer", "baby_dragon", "skeletons", "fireball", "minions"]
	var client_custom_deck: Array[String] = ["knight", "archers", "giant", "musketeer", "baby_dragon", "skeletons", "fireball", "cannon"]
	
	NetworkManager.host_deck = host_custom_deck.duplicate()
	NetworkManager.send_client_deck_to_host(client_custom_deck)
	assert(NetworkManager.client_deck == client_custom_deck, "Client deck not registered on Host")
	
	mm._init_player_decks()
	
	# Verify Team 1 deck composition
	var t1_all_cards: Array[String] = []
	t1_all_cards.append_array(mm.team1_hand)
	t1_all_cards.append(mm.team1_next)
	t1_all_cards.append_array(mm.team1_queue)
	assert(t1_all_cards.size() == 8, "Team 1 deck must have 8 cards")
	assert(t1_all_cards.has("minions") and not t1_all_cards.has("cannon"), "Team 1 should have custom host deck with minions")
	print("  ✓ Host custom deck (with minions) initialized authoritative for Team 1: ", t1_all_cards)
	
	# Verify Team 2 deck composition
	var t2_all_cards: Array[String] = []
	t2_all_cards.append_array(mm.team2_hand)
	t2_all_cards.append(mm.team2_next)
	t2_all_cards.append_array(mm.team2_queue)
	assert(t2_all_cards.size() == 8, "Team 2 deck must have 8 cards")
	assert(t2_all_cards.has("cannon") and not t2_all_cards.has("minions"), "Team 2 should have custom client deck with cannon")
	print("  ✓ Client custom deck (with cannon) initialized authoritative for Team 2: ", t2_all_cards)
	
	# Simulate dynamic client deck sync request
	var client_updated_deck: Array[String] = ["knight", "archers", "giant", "musketeer", "baby_dragon", "minions", "cannon", "arrows"]
	mm.request_sync_state(client_updated_deck)
	var t2_updated_cards: Array[String] = []
	t2_updated_cards.append_array(mm.team2_hand)
	t2_updated_cards.append(mm.team2_next)
	t2_updated_cards.append_array(mm.team2_queue)
	assert(t2_updated_cards.has("minions") and t2_updated_cards.has("cannon"), "Team 2 should reflect updated client deck")
	print("  ✓ Client dynamic deck sync via request_sync_state verified!")
	
	NetworkManager.close_network()
	print("\n========================================================")
	print("🎉 ALL MULTIPLAYER NETWORK & DECK SYNC TESTS PASSED!")
	print("========================================================\n")
	get_tree().quit(0)
