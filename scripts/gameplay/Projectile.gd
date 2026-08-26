extends Node2D

var proj_type: String = "arrow"
var damage: float = 0.0
var splash_radius: float = 0.0
var team: int = 1
var speed: float = 400.0
var target_pos: Vector2 = Vector2.ZERO
var target_entity: Node2D = null
var crown_multiplier: float = 1.0

var start_pos: Vector2 = Vector2.ZERO
var total_distance: float = 0.0
var current_dist: float = 0.0
var arc_height: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func setup(p_type: String, p_from: Vector2, p_to: Vector2, p_damage: float, p_team: int, p_target_node: Node2D = null, p_splash: float = 0.0, p_crown_mult: float = 1.0) -> void:
	proj_type = p_type
	position = p_from
	start_pos = p_from
	target_pos = p_to
	damage = p_damage
	team = p_team
	target_entity = p_target_node
	splash_radius = p_splash
	crown_multiplier = p_crown_mult
	
	total_distance = start_pos.distance_to(target_pos)
	
	match proj_type:
		"arrow":
			speed = 480.0
			arc_height = min(40.0, total_distance * 0.2)
		"cannonball":
			speed = 380.0
			arc_height = min(50.0, total_distance * 0.25)
		"musket_bullet":
			speed = 650.0
			arc_height = 0.0 # Straight shot
		"fireball":
			speed = 360.0
			arc_height = min(60.0, total_distance * 0.3)
		"dark_orb":
			speed = 420.0
			arc_height = min(25.0, total_distance * 0.15)
		_:
			speed = 400.0
			arc_height = 20.0

	if sprite:
		sprite.texture = TextureGenerator.get_projectile_texture(proj_type)

func _ready() -> void:
	if sprite and sprite.texture == null:
		sprite.texture = TextureGenerator.get_projectile_texture(proj_type)

func _process(delta: float) -> void:
	if target_entity and is_instance_valid(target_entity) and not target_entity.is_dead:
		target_pos = target_entity.global_position
		total_distance = start_pos.distance_to(target_pos)

	var dir = (target_pos - start_pos).normalized()
	current_dist += speed * delta
	var t = clamp(current_dist / max(1.0, total_distance), 0.0, 1.0)
	
	var current_ground = start_pos.lerp(target_pos, t)
	var current_y_offset = -sin(t * PI) * arc_height
	
	global_position = current_ground + Vector2(0, current_y_offset)
	
	# Rotation towards movement
	if arc_height > 0.0:
		var next_t = min(1.0, t + 0.05)
		var next_ground = start_pos.lerp(target_pos, next_t)
		var next_y_offset = -sin(next_t * PI) * arc_height
		var next_pos = next_ground + Vector2(0, next_y_offset)
		rotation = (next_pos - global_position).angle() + PI/2.0
	else:
		rotation = (target_pos - start_pos).angle() + PI/2.0
		
	if t >= 1.0:
		_impact()

func _impact() -> void:
	# Authoritative damage execution on Server / Host
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		var arena = get_tree().current_scene.get_node_or_null("Arena")
		if arena:
			if splash_radius > 0.0:
				arena.apply_splash_damage(global_position, splash_radius, damage, team, crown_multiplier)
			elif target_entity and is_instance_valid(target_entity) and not target_entity.is_dead:
				target_entity.take_damage(damage, crown_multiplier)
	
	# Sound & FX
	match proj_type:
		"arrow":
			SoundManager.play_sfx("arrow_hit", -4.0)
		"cannonball":
			SoundManager.play_sfx("giant_punch", -2.0)
		"musket_shot":
			SoundManager.play_sfx("arrow_hit", -2.0)
		"fireball":
			SoundManager.play_sfx("explosion", 0.0)
		"dark_orb":
			SoundManager.play_sfx("sword_hit", -6.0)
			
	_spawn_impact_particles()
	queue_free()

func _spawn_impact_particles() -> void:
	var root = get_parent()
	if not root:
		return
	
	var ring = Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(1.0, 0.8, 0.3, 0.9)
	if proj_type == "fireball":
		ring.default_color = Color(1.0, 0.4, 0.1, 0.9)
		ring.width = 5.0
	elif proj_type == "dark_orb":
		ring.default_color = Color(0.7, 0.2, 0.9, 0.9)
		
	var points = PackedVector2Array()
	var segs = 16
	var rad = splash_radius if splash_radius > 0 else 12.0
	for i in range(segs + 1):
		var angle = i * TAU / segs
		points.append(Vector2(cos(angle), sin(angle)) * rad)
	ring.points = points
	ring.global_position = global_position
	root.add_child(ring)
	
	var tween = ring.create_tween()
	tween.tween_property(ring, "scale", Vector2(1.3, 1.3), 0.2)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ring.queue_free)
