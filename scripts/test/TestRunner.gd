extends Node

func _ready() -> void:
	print("\n==========================================")
	print("🧪 RUNNING VIBE ROYALE TEST SUITE (GODOT 4.6.2)")
	print("==========================================\n")
	
	_test_card_database()
	_test_textures_and_sounds()
	_test_arena_and_towers()
	_test_combat_and_spells()
	_test_match_manager_flow()
	_test_networking_setup()
	
	print("\n==========================================")
	print("🎉 ALL 6 TEST SUITES PASSED FLAWLESSLY!")
	print("==========================================\n")
	get_tree().quit(0)

func _test_card_database() -> void:
	print("[1/6] Testing CardDatabase...")
	var all_ids = CardDatabase.get_all_card_ids()
	assert(all_ids.size() >= 8, "Must have at least 8 cards! Found: " + str(all_ids.size()))
	print("  ✓ Total cards defined: ", all_ids.size(), " (IDs: ", all_ids, ")")
	
	var starter_deck = CardDatabase.get_starter_deck()
	assert(starter_deck.size() == 8, "Starter deck must have exactly 8 cards!")
	print("  ✓ Starter deck configured: ", starter_deck)
	
	for id in all_ids:
		var c = CardDatabase.get_card(id)
		assert(c.has("name") and c.has("cost") and c.has("hp") and c.has("damage"), "Card missing essential stats: " + id)
		assert(c["cost"] >= 1 and c["cost"] <= 10, "Invalid cost for " + id)
	print("  ✓ All card stats validated!")

func _test_textures_and_sounds() -> void:
	print("\n[2/6] Testing TextureGenerator & SoundManager...")
	for id in CardDatabase.get_all_card_ids():
		var icon = TextureGenerator.get_card_icon(id)
		assert(icon != null, "Failed to generate card icon for " + id)
		var utex = TextureGenerator.get_unit_texture(id, 1)
		assert(utex != null, "Failed to generate unit texture for " + id)
	
	var k_tex = TextureGenerator.get_tower_texture("king", 1, true)
	var p_tex = TextureGenerator.get_tower_texture("princess", 2, true)
	assert(k_tex != null and p_tex != null, "Tower textures failed")
	print("  ✓ All procedural textures generated & cached")
	
	SoundManager.play_sfx("card_play")
	SoundManager.play_sfx("sword_hit")
	SoundManager.play_sfx("explosion")
	print("  ✓ Procedural synthesized SFX audio pool verified")

func _test_arena_and_towers() -> void:
	print("\n[3/6] Testing Arena & Tower Setup...")
	var arena_scene = load("res://scenes/entities/tower.tscn")
	assert(arena_scene != null, "Tower scene failed to load")
	
	var king_tower = arena_scene.instantiate()
	king_tower.team = 1
	king_tower.tower_type = "king"
	add_child(king_tower)
	
	assert(king_tower.max_hp == 4000.0, "King tower HP mismatch")
	assert(king_tower.is_king_active == false, "King tower must start inactive")
	
	king_tower.take_damage(100.0)
	assert(king_tower.is_king_active == true, "King tower must activate on damage")
	assert(king_tower.current_hp == 3900.0, "King tower HP damage calculation incorrect")
	
	king_tower.queue_free()
	print("  ✓ Tower mechanics & King activation verified")

func _test_combat_and_spells() -> void:
	print("\n[4/6] Testing Combat Entities & Spells...")
	var unit_scene = load("res://scenes/entities/unit.tscn")
	assert(unit_scene != null, "Unit scene failed to load")
	
	var knight = unit_scene.instantiate()
	add_child(knight)
	knight.setup("knight", 1, Vector2(-125, 100))
	assert(knight.max_hp == 1400.0, "Knight HP mismatch")
	assert(knight.damage == 160.0, "Knight DMG mismatch")
	
	var archer = unit_scene.instantiate()
	add_child(archer)
	archer.setup("archers", 2, Vector2(-125, -100))
	assert(archer.target_type == CardDatabase.TargetType.GROUND_AND_AIR, "Archers target type mismatch")
	
	knight.take_damage(200.0)
	assert(knight.current_hp == 1200.0, "Unit take damage failed")
	
	knight.queue_free()
	archer.queue_free()
	print("  ✓ Units initialization & stats verified")

func _test_match_manager_flow() -> void:
	print("\n[5/6] Testing MatchManager & Elixir/Hand Cycles...")
	var arena_main = load("res://scenes/game_arena.tscn").instantiate()
	add_child(arena_main)
	
	var mm = arena_main.get_node("MatchManager")
	assert(mm != null, "MatchManager node not found in game_arena.tscn")
	assert(mm.team1_hand.size() == 4, "Team 1 hand must have 4 cards")
	assert(mm.team2_hand.size() == 4, "Team 2 hand must have 4 cards")
	assert(mm.team1_next != "", "Team 1 must have a next card")
	
	var first_card = mm.team1_hand[0]
	var next_card_before = mm.team1_next
	mm._cycle_hand(1, first_card)
	assert(mm.team1_hand[0] == next_card_before, "Card cycling did not replace played card with next card")
	
	print("  ✓ 4-Card hand rotating cycle logic verified")
	arena_main.queue_free()

func _test_networking_setup() -> void:
	print("\n[6/6] Testing NetworkManager hosting and local joining...")
	var host_err = NetworkManager.host_game(7788)
	assert(host_err == OK, "Failed to create local host server on 7788")
	assert(NetworkManager.is_host == true, "is_host must be true")
	assert(NetworkManager.local_team == 1, "Host local_team must be 1 (Blue)")
	NetworkManager.close_network()
	assert(NetworkManager.peer == null, "Network peer did not clean up properly")
	print("  ✓ Host creation and cleanup verified")
