extends Node2D

signal tower_destroyed(team: int, tower_type: String)
signal king_activated(team: int)

@export var team: int = 1 # 1 = Blue, 2 = Red
@export var tower_type: String = "princess_left" # "king", "princess_left", "princess_right"

var max_hp: float = 2500.0
var current_hp: float = 2500.0
var damage: float = 90.0
var hit_speed: float = 0.8
var attack_range: float = 220.0
var is_king_active: bool = false
var is_dead: bool = false
var is_building: bool = true

var attack_cooldown: float = 0.0
var target_entity: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/HPLabel
@onready var range_circle: Line2D = $RangeCircle

func _ready() -> void:
	if tower_type == "king":
		max_hp = 4000.0
		damage = 120.0
		hit_speed = 1.0
		attack_range = 240.0
		is_king_active = false
	else:
		max_hp = 2500.0
		damage = 90.0
		hit_speed = 0.8
		attack_range = 220.0
		is_king_active = true
		
	current_hp = max_hp
	_update_visuals()
	_update_hp_bar()

func _update_visuals() -> void:
	if sprite:
		sprite.texture = TextureGenerator.get_tower_texture(
			"king" if tower_type == "king" else "princess",
			team,
			is_king_active
		)

func _update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		if hp_label:
			hp_label.text = str(int(current_hp))
			
		# Differentiate Friendly (Green) vs Enemy (Red) Tower HP Bar
		var is_enemy = (team != NetworkManager.local_team)
		var style_fg = StyleBoxFlat.new()
		style_fg.corner_radius_top_left = 3
		style_fg.corner_radius_top_right = 3
		style_fg.corner_radius_bottom_right = 3
		style_fg.corner_radius_bottom_left = 3
		if is_enemy:
			style_fg.bg_color = Color(0.95, 0.22, 0.25) # Crimson Red (Enemy)
		else:
			style_fg.bg_color = Color(0.2, 0.85, 0.35) # Emerald Green (Friendly)
		hp_bar.add_theme_stylebox_override("fill", style_fg)

func activate_king() -> void:
	if tower_type == "king" and not is_king_active and not is_dead:
		is_king_active = true
		_update_visuals()
		SoundManager.play_sfx("tower_alarm", 2.0)
		king_activated.emit(team)

func client_update_state(hp: float, king_active: bool, dead: bool) -> void:
	current_hp = hp
	_update_hp_bar()
	
	if king_active and not is_king_active:
		activate_king()
		
	if dead and not is_dead:
		_die()

func _process(delta: float) -> void:
	if is_dead:
		return
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	# Authoritative server combat
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		_process_combat()

func _process_combat() -> void:
	if tower_type == "king" and not is_king_active:
		return
		
	if target_entity and (not is_instance_valid(target_entity) or target_entity.is_dead or global_position.distance_to(target_entity.global_position) > attack_range):
		target_entity = null
		
	if target_entity == null:
		target_entity = _find_nearest_enemy()
		
	if target_entity and attack_cooldown <= 0.0:
		_attack_target(target_entity)
		attack_cooldown = hit_speed

func _get_arena() -> Node2D:
	var p = get_parent()
	if p:
		if p.name == "Arena":
			return p as Node2D
		var gp = p.get_parent()
		if gp and gp.name == "Arena":
			return gp as Node2D
	if get_tree() and get_tree().current_scene:
		var a = get_tree().current_scene.get_node_or_null("Arena")
		if a:
			return a as Node2D
		var ga = get_tree().current_scene.find_child("Arena", true, false)
		if ga:
			return ga as Node2D
	return null

func _find_nearest_enemy() -> Node2D:
	var arena = _get_arena()
	if not arena:
		return null
		
	var enemies = arena.get_units_for_team(2 if team == 1 else 1)
	var nearest: Node2D = null
	var min_dist: float = attack_range
	
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= min_dist:
				min_dist = dist
				nearest = enemy
				
	return nearest

func _attack_target(target: Node2D) -> void:
	var arena = _get_arena()
	if not arena:
		return
		
	var proj_type = "cannonball" if tower_type == "king" else "arrow"
	var spawn_pos = global_position + Vector2(0, -15 if team == 1 else 15)
	
	arena.spawn_projectile(proj_type, spawn_pos, target.global_position, damage, team, target)

func take_damage(amount: float, crown_multiplier: float = 1.0) -> void:
	if is_dead:
		return
		
	var final_dmg = amount * crown_multiplier
	current_hp = max(0.0, current_hp - final_dmg)
	_update_hp_bar()
	
	if tower_type == "king" and not is_king_active:
		activate_king()
		
	if sprite:
		var tw = create_tween()
		sprite.modulate = Color(2.0, 1.2, 1.2)
		tw.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)
		
	var arena = _get_arena()
	if arena:
		arena.spawn_floating_text("-" + str(int(final_dmg)), global_position + Vector2(0, -30), Color(1, 0.3, 0.3))
		
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	SoundManager.play_sfx("explosion", 3.0)
	if hp_bar:
		hp_bar.visible = false
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.6)
	
	var arena = _get_arena()
	if arena:
		arena.spawn_explosion_fx(global_position, 40.0)
		
	tower_destroyed.emit(team, tower_type)
