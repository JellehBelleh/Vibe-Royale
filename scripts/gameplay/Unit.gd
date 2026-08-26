extends Node2D

enum State {
	IDLE,
	WALKING,
	ATTACKING,
	DYING
}

@export var unit_id: String = "knight"
@export var team: int = 1
var net_id: int = 0

var max_hp: float = 1400.0
var current_hp: float = 1400.0
var damage: float = 160.0
var hit_speed: float = 1.2
var move_speed: float = 58.0
var attack_range: float = 32.0
var splash_radius: float = 0.0
var is_flying: bool = false
var is_building: bool = false
var building_lifetime: float = 0.0
var target_type: int = 0
var crown_multiplier: float = 1.0

var state: State = State.WALKING
var attack_timer: float = 0.0
var lifetime_timer: float = 0.0
var target_entity: Node2D = null
var lane: String = "left"
var is_dead: bool = false

var target_display_pos: Vector2 = Vector2.ZERO

# Pathfinding bridges (Canonical)
const BRIDGE_LEFT = Vector2(-125.0, 0.0)
const BRIDGE_RIGHT = Vector2(125.0, 0.0)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var shadow: Sprite2D = $Shadow

func setup(p_id: String, p_team: int, p_pos: Vector2) -> void:
	unit_id = p_id
	team = p_team
	global_position = p_pos
	target_display_pos = p_pos
	
	var data = CardDatabase.get_card(unit_id)
	if data.is_empty():
		return
		
	max_hp = data.get("hp", 1000.0)
	current_hp = max_hp
	damage = data.get("damage", 100.0)
	hit_speed = data.get("hit_speed", 1.0)
	move_speed = data.get("move_speed", 50.0)
	attack_range = data.get("range", 30.0)
	splash_radius = data.get("splash_radius", 0.0)
	is_flying = data.get("is_flying", false)
	is_building = data.get("is_building", false)
	building_lifetime = data.get("building_lifetime", 0.0)
	target_type = data.get("target_type", 0)
	crown_multiplier = data.get("crown_mult", 1.0)
	
	lane = "left" if global_position.x <= 0 else "right"
	if is_building:
		state = State.IDLE
		
	_update_visuals()
	_update_hp_bar()

func _ready() -> void:
	_update_visuals()
	_update_hp_bar()

func _update_visuals() -> void:
	if sprite:
		sprite.texture = TextureGenerator.get_unit_texture(unit_id, team)
	if shadow:
		shadow.scale = Vector2(0.8, 0.4) if not is_flying else Vector2(0.6, 0.3)
		if is_flying:
			shadow.position = Vector2(0, 20)
			sprite.position = Vector2(0, -15)
		else:
			shadow.position = Vector2(0, 10)
			sprite.position = Vector2(0, 0)

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		
		# Differentiate Friendly (Green) vs Enemy (Red) HP Bar
		var is_enemy = (team != NetworkManager.local_team)
		var style_fg = StyleBoxFlat.new()
		style_fg.corner_radius_top_left = 2
		style_fg.corner_radius_top_right = 2
		style_fg.corner_radius_bottom_right = 2
		style_fg.corner_radius_bottom_left = 2
		if is_enemy:
			style_fg.bg_color = Color(0.95, 0.22, 0.25) # Crimson Red (Enemy)
		else:
			style_fg.bg_color = Color(0.2, 0.85, 0.35) # Emerald Green (Friendly)
		hp_bar.add_theme_stylebox_override("fill", style_fg)

func client_update_state(local_pos: Vector2, hp: float, m_hp: float, u_state: int) -> void:
	target_display_pos = local_pos
	current_hp = hp
	max_hp = m_hp
	state = u_state as State
	_update_hp_bar()

func _process(delta: float) -> void:
	if is_dead:
		return
		
	# Authoritative server logic
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		# Building lifetime decay
		if is_building and building_lifetime > 0.0:
			lifetime_timer += delta
			current_hp -= (max_hp / building_lifetime) * delta
			_update_hp_bar()
			if current_hp <= 0.0:
				_die()
				return
				
		if attack_timer > 0.0:
			attack_timer -= delta
			
		_process_unit_ai(delta)
	else:
		# Client side smooth position interpolation
		global_position = global_position.lerp(target_display_pos, min(1.0, delta * 20.0))
		
	_animate_unit(delta)

func _process_unit_ai(delta: float) -> void:
	if target_entity:
		if not is_instance_valid(target_entity) or target_entity.is_dead:
			target_entity = null
		else:
			var dist = global_position.distance_to(target_entity.global_position)
			if dist > 260.0:
				target_entity = null

	if target_entity == null:
		target_entity = _acquire_best_target()
		
	if target_entity != null:
		var dist_to_target = global_position.distance_to(target_entity.global_position)
		if dist_to_target <= attack_range:
			state = State.ATTACKING
			if attack_timer <= 0.0:
				_perform_attack()
				attack_timer = hit_speed
		else:
			if not is_building:
				state = State.WALKING
				_move_towards(target_entity.global_position, delta)
	else:
		if not is_building:
			state = State.WALKING
			var waypoint = _get_lane_waypoint()
			_move_towards(waypoint, delta)

func _acquire_best_target() -> Node2D:
	var arena = get_tree().current_scene.get_node_or_null("Arena")
	if not arena:
		return null
		
	var enemy_team = 2 if team == 1 else 1
	var candidate: Node2D = null
	var min_dist: float = 190.0
	
	if target_type == CardDatabase.TargetType.BUILDINGS_ONLY:
		return arena.get_target_tower_for_unit(self)
		
	var enemy_units = arena.get_units_for_team(enemy_team)
	for u in enemy_units:
		if not is_instance_valid(u) or u.is_dead:
			continue
		if u.is_flying and target_type == CardDatabase.TargetType.GROUND:
			continue
		var dist = global_position.distance_to(u.global_position)
		if dist < min_dist:
			min_dist = dist
			candidate = u
			
	if candidate == null:
		candidate = arena.get_target_tower_for_unit(self)
		
	return candidate

func _get_lane_waypoint() -> Vector2:
	var arena = get_tree().current_scene.get_node_or_null("Arena")
	var target_tower = arena.get_target_tower_for_unit(self) if arena else null
	var tower_pos = target_tower.global_position if target_tower else Vector2(0, -310 if team == 1 else 310)
	
	if is_flying:
		return tower_pos
		
	var bridge = BRIDGE_LEFT if lane == "left" else BRIDGE_RIGHT
	var is_on_home_side = (team == 1 and global_position.y > 15.0) or (team == 2 and global_position.y < -15.0)
	
	if is_on_home_side:
		if abs(global_position.y) > 10.0:
			return Vector2(bridge.x, global_position.y - (30.0 if team == 1 else -30.0))
		return bridge
	else:
		return tower_pos

func _move_towards(target_pos: Vector2, delta: float) -> void:
	var dir = (target_pos - global_position).normalized()
	global_position += dir * move_speed * delta

func _perform_attack() -> void:
	if not target_entity or not is_instance_valid(target_entity) or target_entity.is_dead:
		return
		
	var arena = get_tree().current_scene.get_node_or_null("Arena")
	if not arena:
		return
		
	match unit_id:
		"knight":
			SoundManager.play_sfx("sword_hit", 0.0)
			_deal_direct_damage(target_entity)
		"skeletons":
			SoundManager.play_sfx("sword_hit", -4.0)
			_deal_direct_damage(target_entity)
		"giant":
			SoundManager.play_sfx("giant_punch", 2.0)
			_deal_direct_damage(target_entity)
		"archers":
			SoundManager.play_sfx("arrow_shoot", -2.0)
			arena.spawn_projectile("arrow", global_position, target_entity.global_position, damage, team, target_entity)
		"musketeer":
			SoundManager.play_sfx("musket_shot", 2.0)
			arena.spawn_projectile("musket_bullet", global_position, target_entity.global_position, damage, team, target_entity)
		"baby_dragon":
			SoundManager.play_sfx("dragon_breath", 0.0)
			arena.spawn_projectile("fireball", global_position, target_entity.global_position, damage, team, target_entity, splash_radius)
		"minions":
			SoundManager.play_sfx("dragon_breath", -4.0)
			arena.spawn_projectile("dark_orb", global_position, target_entity.global_position, damage, team, target_entity)
		"cannon":
			SoundManager.play_sfx("giant_punch", 0.0)
			arena.spawn_projectile("cannonball", global_position, target_entity.global_position, damage, team, target_entity)
		_:
			_deal_direct_damage(target_entity)

func _deal_direct_damage(target: Node2D) -> void:
	if splash_radius > 0.0:
		var arena = get_tree().current_scene.get_node_or_null("Arena")
		if arena:
			arena.apply_splash_damage(target.global_position, splash_radius, damage, team, crown_multiplier)
	else:
		target.take_damage(damage, crown_multiplier)

func take_damage(amount: float, p_crown_mult: float = 1.0) -> void:
	if is_dead:
		return
		
	current_hp = max(0.0, current_hp - amount)
	_update_hp_bar()
	
	if sprite:
		var tw = create_tween()
		sprite.modulate = Color(2.0, 1.2, 1.2)
		tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.12)
		
	var arena = get_tree().current_scene.get_node_or_null("Arena")
	if arena:
		arena.spawn_floating_text("-" + str(int(amount)), global_position + Vector2(randf_range(-10, 10), -20), Color(1, 0.4, 0.4))
		
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DYING
	
	var arena = get_tree().current_scene.get_node_or_null("Arena")
	if arena:
		arena.remove_unit(self)
		arena.spawn_elixir_dissolve_fx(global_position)
		
	queue_free()

func _animate_unit(_delta: float) -> void:
	if not sprite or is_dead:
		return
		
	if state == State.WALKING:
		sprite.position.y = (sin(Time.get_ticks_msec() * 0.015) * 3.0) + (-15.0 if is_flying else 0.0)
	elif state == State.ATTACKING:
		var lunge = sin(attack_timer / max(0.1, hit_speed) * PI) * 5.0
		sprite.position.x = lunge if team == 1 else -lunge
	else:
		sprite.position = Vector2(0, -15 if is_flying else 0)
