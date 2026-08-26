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
	
	# Switch to client perspective to verify snapshot application
	NetworkManager.local_team = 2
	arena.apply_world_snapshot(snapshot)
	var client_unit = arena.units_by_net_id[unit.net_id]
	assert(client_unit.target_display_pos.y < 0 or client_unit.target_display_pos.y > 0, "Target display pos not set")
	print("  ✓ Client applied world snapshot successfully! Client display pos: ", client_unit.target_display_pos)
	
	NetworkManager.close_network()
	print("  ✓ All multiplayer sync & perspective tests passed flawlessly!")
	get_tree().quit(0)
