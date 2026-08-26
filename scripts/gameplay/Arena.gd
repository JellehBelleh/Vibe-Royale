extends Node2D

const ARENA_WIDTH: float = 460.0
const ARENA_HEIGHT: float = 840.0

var units_team1: Array[Node2D] = []
var units_team2: Array[Node2D] = []
var units_by_net_id: Dictionary = {}
var next_net_id: int = 1

var towers_team1: Dictionary = {}
var towers_team2: Dictionary = {}

@onready var unit_container: Node2D = $UnitContainer
@onready var projectile_container: Node2D = $ProjectileContainer
@onready var fx_container: Node2D = $FXContainer
@onready var terrain_draw: Node2D = $TerrainDraw
@onready var drop_zone_overlay: Node2D = $DropZoneOverlay

var unit_scene = preload("res://scenes/entities/unit.tscn")
var projectile_scene = preload("res://scenes/entities/projectile.tscn")
var spell_scene = preload("res://scenes/entities/spell_effect.tscn")
var tower_scene = preload("res://scenes/entities/tower.tscn")
var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func _ready() -> void:
	_init_towers()
	_init_terrain()

# Coordinate transformations between canonical (server) and local (client display)
func canonical_to_local(p: Vector2) -> Vector2:
	return Vector2(-p.x, -p.y) if NetworkManager.local_team == 2 else p

func local_to_canonical(p: Vector2) -> Vector2:
	return Vector2(-p.x, -p.y) if NetworkManager.local_team == 2 else p

func _init_towers() -> void:
	if NetworkManager.local_team == 2:
		# Player 2 (Red): Red towers at bottom (home), Blue towers at top (enemy)
		_spawn_tower(2, "king", Vector2(0, 310))
		_spawn_tower(2, "princess_left", Vector2(125, 200))
		_spawn_tower(2, "princess_right", Vector2(-125, 200))

		_spawn_tower(1, "king", Vector2(0, -310))
		_spawn_tower(1, "princess_left", Vector2(125, -200))
		_spawn_tower(1, "princess_right", Vector2(-125, -200))
	else:
		# Player 1 (Blue / Host) or Solo Bot mode: Blue at bottom, Red at top
		_spawn_tower(1, "king", Vector2(0, 310))
		_spawn_tower(1, "princess_left", Vector2(-125, 200))
		_spawn_tower(1, "princess_right", Vector2(125, 200))

		_spawn_tower(2, "king", Vector2(0, -310))
		_spawn_tower(2, "princess_left", Vector2(-125, -200))
		_spawn_tower(2, "princess_right", Vector2(125, -200))

func _spawn_tower(team: int, type: String, pos: Vector2) -> void:
	var tower = tower_scene.instantiate()
	tower.team = team
	tower.tower_type = type
	tower.position = pos
	add_child(tower)
	
	if team == 1:
		towers_team1[type] = tower
	else:
		towers_team2[type] = tower
		
	tower.tower_destroyed.connect(_on_tower_destroyed)

func _init_terrain() -> void:
	if terrain_draw:
		terrain_draw.queue_redraw()

func _draw_terrain_canvas(canvas: Node2D) -> void:
	var half_w = ARENA_WIDTH / 2.0
	var half_h = ARENA_HEIGHT / 2.0
	
	# Background outer rim
	canvas.draw_rect(Rect2(-half_w - 20, -half_h - 20, ARENA_WIDTH + 40, ARENA_HEIGHT + 40), Color(0.18, 0.35, 0.15))
	canvas.draw_rect(Rect2(-half_w, -half_h, ARENA_WIDTH, ARENA_HEIGHT), Color(0.3, 0.65, 0.25))
	
	# Checkerboard grass pattern
	var cell_size = 40.0
	var cols = int(ARENA_WIDTH / cell_size)
	var rows = int(ARENA_HEIGHT / cell_size)
	for r in range(rows):
		for c in range(cols):
			if (r + c) % 2 == 0:
				var rx = -half_w + c * cell_size
				var ry = -half_h + r * cell_size
				canvas.draw_rect(Rect2(rx, ry, cell_size, cell_size), Color(0.34, 0.7, 0.28, 0.35))
				
	# Dirt paths connecting lanes
	var path_col = Color(0.72, 0.58, 0.38)
	canvas.draw_rect(Rect2(-140, -320, 30, 640), path_col)
	canvas.draw_rect(Rect2(110, -320, 30, 640), path_col)
	canvas.draw_line(Vector2(-125, 200), Vector2(0, 310), path_col, 24)
	canvas.draw_line(Vector2(125, 200), Vector2(0, 310), path_col, 24)
	canvas.draw_line(Vector2(-125, -200), Vector2(0, -310), path_col, 24)
	canvas.draw_line(Vector2(125, -200), Vector2(0, -310), path_col, 24)

	# River in center
	canvas.draw_rect(Rect2(-half_w, -22, ARENA_WIDTH, 44), Color(0.2, 0.5, 0.85))
	for i in range(8):
		var wx = -half_w + i * 60 + 15
		canvas.draw_line(Vector2(wx, -8), Vector2(wx + 30, -8), Color(0.5, 0.8, 1.0, 0.6), 3)
		canvas.draw_line(Vector2(wx + 15, 8), Vector2(wx + 45, 8), Color(0.5, 0.8, 1.0, 0.6), 3)
		
	# Stone Bridges (Left & Right)
	_draw_bridge(canvas, Vector2(-125, 0))
	_draw_bridge(canvas, Vector2(125, 0))
	
	# Arena Stone Border Walls
	canvas.draw_rect(Rect2(-half_w, -half_h, ARENA_WIDTH, 12), Color(0.45, 0.48, 0.52))
	canvas.draw_rect(Rect2(-half_w, half_h - 12, ARENA_WIDTH, 12), Color(0.45, 0.48, 0.52))
	canvas.draw_rect(Rect2(-half_w, -half_h, 12, ARENA_HEIGHT), Color(0.45, 0.48, 0.52))
	canvas.draw_rect(Rect2(half_w - 12, -half_h, 12, ARENA_HEIGHT), Color(0.45, 0.48, 0.52))

func _draw_bridge(canvas: Node2D, center: Vector2) -> void:
	canvas.draw_rect(Rect2(center.x - 26, center.y - 28, 52, 56), Color(0.5, 0.53, 0.58))
	canvas.draw_rect(Rect2(center.x - 22, center.y - 26, 44, 52), Color(0.55, 0.38, 0.2))
	for y_off in [-18, -6, 6, 18]:
		canvas.draw_line(Vector2(center.x - 22, center.y + y_off), Vector2(center.x + 22, center.y + y_off), Color(0.35, 0.22, 0.12), 2)
	canvas.draw_rect(Rect2(center.x - 26, center.y - 28, 6, 56), Color(0.6, 0.63, 0.68))
	canvas.draw_rect(Rect2(center.x + 20, center.y - 28, 6, 56), Color(0.6, 0.63, 0.68))

# --- DEPLOYMENT VALIDATION (LOCAL SCREEN COORDINATES) ---

func is_valid_deployment(local_pos: Vector2, _local_team: int, is_spell: bool) -> bool:
	if is_spell:
		return abs(local_pos.x) <= (ARENA_WIDTH / 2.0 - 15.0) and abs(local_pos.y) <= (ARENA_HEIGHT / 2.0 - 20.0)
		
	if abs(local_pos.y) < 22.0:
		return false
		
	if abs(local_pos.x) > (ARENA_WIDTH / 2.0 - 20.0) or abs(local_pos.y) > (ARENA_HEIGHT / 2.0 - 20.0):
		return false

	# For local player (both Blue and Red), home base is ALWAYS bottom (Y >= 25)
	if local_pos.y >= 25.0:
		return true
		
	# Territory expansion if enemy princess towers are dead
	var enemy_towers = towers_team2 if NetworkManager.local_team == 1 else towers_team1
	var left_key = "princess_left" if NetworkManager.local_team == 1 else "princess_right"
	var right_key = "princess_right" if NetworkManager.local_team == 1 else "princess_left"
	
	var left_dead = not enemy_towers.has(left_key) or enemy_towers[left_key].is_dead
	var right_dead = not enemy_towers.has(right_key) or enemy_towers[right_key].is_dead
	
	if left_dead and local_pos.x < 0 and local_pos.y >= -130.0:
		return true
	if right_dead and local_pos.x > 0 and local_pos.y >= -130.0:
		return true
		
	return false

# Server-side canonical deployment check
func is_valid_canonical_deployment(canonical_pos: Vector2, team: int, is_spell: bool) -> bool:
	if is_spell:
		return abs(canonical_pos.x) <= (ARENA_WIDTH / 2.0 - 15.0) and abs(canonical_pos.y) <= (ARENA_HEIGHT / 2.0 - 20.0)
	if abs(canonical_pos.y) < 22.0:
		return false
	if abs(canonical_pos.x) > (ARENA_WIDTH / 2.0 - 20.0) or abs(canonical_pos.y) > (ARENA_HEIGHT / 2.0 - 20.0):
		return false

	if team == 1:
		if canonical_pos.y >= 25.0:
			return true
		var r_l_dead = not towers_team2.has("princess_left") or towers_team2["princess_left"].is_dead
		var r_r_dead = not towers_team2.has("princess_right") or towers_team2["princess_right"].is_dead
		if r_l_dead and canonical_pos.x < 0 and canonical_pos.y >= -130.0:
			return true
		if r_r_dead and canonical_pos.x > 0 and canonical_pos.y >= -130.0:
			return true
		return false
	else:
		if canonical_pos.y <= -25.0:
			return true
		var b_l_dead = not towers_team1.has("princess_left") or towers_team1["princess_left"].is_dead
		var b_r_dead = not towers_team1.has("princess_right") or towers_team1["princess_right"].is_dead
		if b_l_dead and canonical_pos.x < 0 and canonical_pos.y <= 130.0:
			return true
		if b_r_dead and canonical_pos.x > 0 and canonical_pos.y <= 130.0:
			return true
		return false

# --- SPAWNING (SERVER AUTHORITY) ---

func spawn_card(card_id: String, team: int, canonical_pos: Vector2) -> void:
	var card_data = CardDatabase.get_card(card_id)
	if card_data.is_empty():
		return
		
	if card_data.get("is_spell", false):
		_spawn_spell(card_id, team, canonical_pos, card_data)
	else:
		_spawn_troops(card_id, team, canonical_pos, card_data)

func _spawn_troops(card_id: String, team: int, pos: Vector2, data: Dictionary) -> void:
	var count = data.get("count", 1)
	SoundManager.play_sfx("card_play", 0.0)
	
	if count == 1:
		_instantiate_unit(card_id, team, pos)
	elif count == 2:
		_instantiate_unit(card_id, team, pos + Vector2(-16, 0))
		_instantiate_unit(card_id, team, pos + Vector2(16, 0))
	elif count == 3:
		_instantiate_unit(card_id, team, pos + Vector2(0, -18))
		_instantiate_unit(card_id, team, pos + Vector2(-16, 14))
		_instantiate_unit(card_id, team, pos + Vector2(16, 14))
	elif count == 4:
		SoundManager.play_sfx("skeleton_spawn", 0.0)
		_instantiate_unit(card_id, team, pos + Vector2(0, -16))
		_instantiate_unit(card_id, team, pos + Vector2(0, 16))
		_instantiate_unit(card_id, team, pos + Vector2(-16, 0))
		_instantiate_unit(card_id, team, pos + Vector2(16, 0))

func _instantiate_unit(unit_id: String, team: int, canonical_pos: Vector2) -> Node2D:
	var net_id = next_net_id
	next_net_id += 1
	
	var unit = unit_scene.instantiate()
	unit.net_id = net_id
	unit.setup(unit_id, team, canonical_pos)
	unit_container.add_child(unit)
	
	units_by_net_id[net_id] = unit
	if team == 1:
		units_team1.append(unit)
	else:
		units_team2.append(unit)
		
	return unit

func _spawn_spell(spell_id: String, team: int, canonical_pos: Vector2, data: Dictionary) -> void:
	var dmg = data.get("damage", 300.0)
	var radius = data.get("splash_radius", 75.0)
	var crown_mult = data.get("crown_mult", 0.35)
	
	var spell = spell_scene.instantiate()
	fx_container.add_child(spell)
	spell.setup(spell_id, team, canonical_pos, dmg, radius, crown_mult)
	
	var mm = get_parent().get_node_or_null("MatchManager")
	if mm and multiplayer.has_multiplayer_peer():
		mm.rpc("sync_spawn_spell", spell_id, team, canonical_pos.x, canonical_pos.y, dmg, radius, crown_mult)

func spawn_projectile(p_type: String, p_from: Vector2, p_to: Vector2, p_dmg: float, p_team: int, p_target: Node2D = null, p_splash: float = 0.0, p_crown_mult: float = 1.0) -> void:
	var proj = projectile_scene.instantiate()
	projectile_container.add_child(proj)
	proj.setup(p_type, p_from, p_to, p_dmg, p_team, p_target, p_splash, p_crown_mult)
	
	var mm = get_parent().get_node_or_null("MatchManager")
	if mm and multiplayer.has_multiplayer_peer():
		mm.rpc("sync_spawn_projectile", p_type, p_from.x, p_from.y, p_to.x, p_to.y, p_dmg, p_team, p_splash)

# --- CLIENT RENDERING HOOKS ---

func client_spawn_visual_projectile(p_type: String, local_from: Vector2, local_to: Vector2, p_dmg: float, p_team: int, p_splash: float = 0.0) -> void:
	var proj = projectile_scene.instantiate()
	projectile_container.add_child(proj)
	proj.setup(p_type, local_from, local_to, p_dmg, p_team, null, p_splash, 1.0)

func client_spawn_visual_spell(spell_id: String, p_team: int, local_pos: Vector2, p_dmg: float, p_radius: float, p_crown_mult: float) -> void:
	var spell = spell_scene.instantiate()
	fx_container.add_child(spell)
	spell.setup(spell_id, p_team, local_pos, p_dmg, p_radius, p_crown_mult)

# --- WORLD STATE SYNCHRONIZATION ---

func get_world_snapshot() -> Dictionary:
	var unit_list: Array = []
	for net_id in units_by_net_id:
		var u = units_by_net_id[net_id]
		if is_instance_valid(u) and not u.is_dead:
			unit_list.append([
				u.net_id,
				u.unit_id,
				u.team,
				u.global_position.x,
				u.global_position.y,
				u.current_hp,
				u.max_hp,
				int(u.state)
			])
			
	var tower_list: Array = []
	for t_dict in [towers_team1, towers_team2]:
		for type in t_dict:
			var t = t_dict[type]
			if is_instance_valid(t):
				tower_list.append([
					t.team,
					t.tower_type,
					t.current_hp,
					t.is_king_active,
					t.is_dead
				])
				
	return {
		"units": unit_list,
		"towers": tower_list
	}

func apply_world_snapshot(snapshot: Dictionary) -> void:
	if not snapshot.has("units") or not snapshot.has("towers"):
		return
		
	var active_ids: Dictionary = {}
	
	# Synchronize Units
	for u_data in snapshot["units"]:
		var net_id = u_data[0]
		var u_id = u_data[1]
		var u_team = u_data[2]
		var can_pos = Vector2(u_data[3], u_data[4])
		var local_pos = canonical_to_local(can_pos)
		var hp = u_data[5]
		var m_hp = u_data[6]
		var u_state = u_data[7]
		
		active_ids[net_id] = true
		
		var unit: Node2D = null
		if units_by_net_id.has(net_id) and is_instance_valid(units_by_net_id[net_id]):
			unit = units_by_net_id[net_id]
		else:
			unit = unit_scene.instantiate()
			unit.net_id = net_id
			unit.setup(u_id, u_team, local_pos)
			unit_container.add_child(unit)
			units_by_net_id[net_id] = unit
			if u_team == 1:
				units_team1.append(unit)
			else:
				units_team2.append(unit)
				
		unit.client_update_state(local_pos, hp, m_hp, u_state)
		
	# Remove units no longer present on server
	var to_remove: Array = []
	for net_id in units_by_net_id:
		if not active_ids.has(net_id):
			to_remove.append(net_id)
			
	for net_id in to_remove:
		var u = units_by_net_id[net_id]
		if is_instance_valid(u):
			remove_unit(u)
			spawn_elixir_dissolve_fx(u.global_position)
			u.queue_free()
		units_by_net_id.erase(net_id)
		
	# Synchronize Towers
	for t_data in snapshot["towers"]:
		var t_team = t_data[0]
		var t_type = t_data[1]
		var t_hp = t_data[2]
		var king_active = t_data[3]
		var dead = t_data[4]
		
		var t_dict = towers_team1 if t_team == 1 else towers_team2
		if t_dict.has(t_type):
			var tower = t_dict[t_type]
			if is_instance_valid(tower):
				tower.client_update_state(t_hp, king_active, dead)

# --- COMBAT UTILITIES ---

func remove_unit(unit: Node2D) -> void:
	units_team1.erase(unit)
	units_team2.erase(unit)
	if unit.has_method("get") and unit.get("net_id") != null:
		units_by_net_id.erase(unit.net_id)

func get_units_for_team(team: int) -> Array[Node2D]:
	return units_team1 if team == 1 else units_team2

func get_target_tower_for_unit(unit: Node2D) -> Node2D:
	var enemy_towers = towers_team2 if unit.team == 1 else towers_team1
	
	var princess_key = "princess_left" if unit.lane == "left" else "princess_right"
	if enemy_towers.has(princess_key) and is_instance_valid(enemy_towers[princess_key]) and not enemy_towers[princess_key].is_dead:
		return enemy_towers[princess_key]
		
	var other_princess = "princess_right" if unit.lane == "left" else "princess_left"
	if enemy_towers.has(other_princess) and is_instance_valid(enemy_towers[other_princess]) and not enemy_towers[other_princess].is_dead:
		return enemy_towers[other_princess]
		
	if enemy_towers.has("king") and is_instance_valid(enemy_towers["king"]) and not enemy_towers["king"].is_dead:
		return enemy_towers["king"]
		
	return null

func apply_splash_damage(epicenter: Vector2, radius: float, dmg: float, team: int, crown_mult: float = 1.0) -> void:
	var enemy_team = 2 if team == 1 else 1
	var enemy_units = get_units_for_team(enemy_team)
	
	for u in enemy_units:
		if is_instance_valid(u) and not u.is_dead:
			if epicenter.distance_to(u.global_position) <= radius:
				u.take_damage(dmg, crown_mult)
				
	var enemy_towers = towers_team2 if team == 1 else towers_team1
	for type in enemy_towers:
		var t = enemy_towers[type]
		if is_instance_valid(t) and not t.is_dead:
			if epicenter.distance_to(t.global_position) <= radius:
				t.take_damage(dmg, crown_mult)

func spawn_floating_text(text: String, pos: Vector2, col: Color) -> void:
	var ftext = floating_text_scene.instantiate()
	fx_container.add_child(ftext)
	ftext.setup(text, canonical_to_local(pos), col)

func spawn_explosion_fx(pos: Vector2, _radius: float = 30.0) -> void:
	SoundManager.play_sfx("explosion", 0.0)

func spawn_elixir_dissolve_fx(pos: Vector2) -> void:
	pass

func _on_tower_destroyed(destroyed_team: int, tower_type: String) -> void:
	var mm = get_parent().get_node_or_null("MatchManager")
	if mm and (NetworkManager.is_host or not NetworkManager.is_multiplayer_game):
		mm.on_tower_destroyed(destroyed_team, tower_type)
