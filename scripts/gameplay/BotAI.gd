extends Node

var match_manager: Node = null
var think_timer: float = 0.0
var push_lane: String = "left"

func setup(p_manager: Node) -> void:
	match_manager = p_manager
	push_lane = "left" if randf() < 0.5 else "right"

func _process(delta: float) -> void:
	if not match_manager or match_manager.is_game_over:
		return
		
	think_timer += delta
	if think_timer >= randf_range(1.0, 1.8):
		think_timer = 0.0
		_evaluate_and_play()

func _evaluate_and_play() -> void:
	var elixir = match_manager.team2_elixir
	var hand = match_manager.team2_hand
	var arena = match_manager.arena
	if not arena:
		return

	var threats = _find_threats_in_red_zone(arena)
	
	# 1. DEFENSE / REACT TO THREATS
	if threats.size() > 0:
		var primary_threat = threats[0]
		var threat_pos = primary_threat.global_position
		
		# Swarm threat -> use Arrows or Fireball or Baby Dragon
		if _is_swarm_threat(threats):
			if "arrows" in hand and elixir >= 3:
				_play_card("arrows", threat_pos)
				return
			if "fireball" in hand and elixir >= 4:
				_play_card("fireball", threat_pos)
				return
			if "baby_dragon" in hand and elixir >= 4:
				_play_card("baby_dragon", Vector2(threat_pos.x, min(-40.0, threat_pos.y - 40.0)))
				return
				
		# Tank threat (Giant) -> use Cannon or Knight or Skeletons
		if primary_threat.unit_id == "giant":
			if "cannon" in hand and elixir >= 3:
				_play_card("cannon", Vector2(0, -100))
				return
			if "skeletons" in hand and elixir >= 1:
				_play_card("skeletons", threat_pos + Vector2(0, -30))
				return
			if "musketeer" in hand and elixir >= 4:
				_play_card("musketeer", Vector2(threat_pos.x + 40, -120))
				return

		# General troop defense -> drop Knight or Archers near tower
		if "knight" in hand and elixir >= 3:
			_play_card("knight", Vector2(threat_pos.x, min(-35.0, threat_pos.y - 30.0)))
			return
		if "archers" in hand and elixir >= 3:
			_play_card("archers", Vector2(threat_pos.x, -140))
			return
		if "musketeer" in hand and elixir >= 4:
			_play_card("musketeer", Vector2(threat_pos.x, -140))
			return

	# 2. FINISHER SPELL ON TOWER
	if "fireball" in hand and elixir >= 4:
		var blue_left = arena.towers_team1.get("princess_left")
		var blue_right = arena.towers_team1.get("princess_right")
		if blue_left and not blue_left.is_dead and blue_left.current_hp < 250:
			_play_card("fireball", blue_left.global_position)
			return
		if blue_right and not blue_right.is_dead and blue_right.current_hp < 250:
			_play_card("fireball", blue_right.global_position)
			return

	# 3. OFFENSIVE PUSH (High Elixir)
	if elixir >= 7.5:
		var lane_x = -125.0 if push_lane == "left" else 125.0
		
		if "giant" in hand and elixir >= 5:
			_play_card("giant", Vector2(lane_x, -280))
			return
		elif "baby_dragon" in hand and elixir >= 4:
			_play_card("baby_dragon", Vector2(lane_x, -260))
			return
		elif "knight" in hand and elixir >= 3:
			_play_card("knight", Vector2(lane_x, -260))
			return
		elif "musketeer" in hand and elixir >= 4:
			_play_card("musketeer", Vector2(lane_x, -280))
			return
		elif "archers" in hand and elixir >= 3:
			_play_card("archers", Vector2(lane_x, -280))
			return
			
	# 4. PREVENT ELIXIR LEAK (Elixir >= 9.5)
	if elixir >= 9.5:
		if "skeletons" in hand and elixir >= 1:
			_play_card("skeletons", Vector2(0, -320))
			return
		if "archers" in hand and elixir >= 3:
			_play_card("archers", Vector2(-125, -280))
			return
		if "minions" in hand and elixir >= 3:
			_play_card("minions", Vector2(125, -280))
			return

func _find_threats_in_red_zone(arena: Node2D) -> Array[Node2D]:
	var list: Array[Node2D] = []
	for u in arena.units_team1:
		if is_instance_valid(u) and not u.is_dead and u.global_position.y < 80.0:
			list.append(u)
	# Sort by proximity to king tower
	list.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	return list

func _is_swarm_threat(threats: Array[Node2D]) -> bool:
	var count = 0
	for u in threats:
		if u.unit_id in ["skeletons", "minions", "archers"]:
			count += 1
	return count >= 3

func _play_card(card_id: String, pos: Vector2) -> void:
	# Ensure Red spawns within valid territory
	var card_data = CardDatabase.get_card(card_id)
	if not card_data.get("is_spell", false):
		pos.y = min(-30.0, pos.y)
		pos.x = clamp(pos.x, -190.0, 190.0)
		
	match_manager._server_execute_play_card(2, card_id, pos)
	push_lane = "right" if push_lane == "left" else "left"
