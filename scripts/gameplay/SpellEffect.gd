extends Node2D

var spell_id: String = "fireball"
var team: int = 1
var target_pos: Vector2 = Vector2.ZERO
var damage: float = 0.0
var splash_radius: float = 75.0
var crown_multiplier: float = 0.35
var travel_time: float = 0.8
var elapsed: float = 0.0
var origin_pos: Vector2 = Vector2.ZERO

@onready var indicator: Line2D = $Indicator
@onready var spell_sprite: Sprite2D = $SpellSprite

func setup(p_id: String, p_team: int, p_pos: Vector2, p_dmg: float, p_radius: float, p_crown_mult: float) -> void:
	spell_id = p_id
	team = p_team
	target_pos = p_pos
	damage = p_dmg
	splash_radius = p_radius
	crown_multiplier = p_crown_mult
	
	# Origin is the player's side of the arena
	origin_pos = Vector2(0, 420.0 if team == 1 else -420.0)
	position = target_pos

func _ready() -> void:
	# Draw placement radius indicator
	_draw_indicator()
	
	if spell_id == "fireball":
		SoundManager.play_sfx("fireball_cast", 0.0)
	else:
		SoundManager.play_sfx("arrow_shoot", 0.0)

func _draw_indicator() -> void:
	if not indicator:
		indicator = Line2D.new()
		add_child(indicator)
	
	indicator.width = 2.5
	indicator.default_color = Color(1.0, 0.4, 0.2, 0.6) if spell_id == "fireball" else Color(1.0, 0.85, 0.3, 0.6)
	var points = PackedVector2Array()
	var segs = 32
	for i in range(segs + 1):
		var angle = i * TAU / segs
		points.append(Vector2(cos(angle), sin(angle)) * splash_radius)
	indicator.points = points

func _process(delta: float) -> void:
	elapsed += delta
	var t = clamp(elapsed / travel_time, 0.0, 1.0)
	
	if spell_sprite:
		var current_ground = origin_pos.lerp(target_pos, t)
		var height = -sin(t * PI) * 120.0
		spell_sprite.global_position = current_ground + Vector2(0, height)
		spell_sprite.rotation += delta * 12.0
		spell_sprite.scale = Vector2.ONE * lerp(0.8, 1.3, sin(t * PI))
		
	if elapsed >= travel_time:
		_detonate()

func _detonate() -> void:
	# Apply damage on Server / Host
	if NetworkManager.is_host or not NetworkManager.is_multiplayer_game:
		var arena = get_tree().current_scene.get_node_or_null("Arena")
		if arena:
			arena.apply_splash_damage(target_pos, splash_radius, damage, team, crown_multiplier)
	
	# Explosion FX & SFX
	if spell_id == "fireball":
		SoundManager.play_sfx("explosion", 2.0)
	else:
		SoundManager.play_sfx("arrow_hit", 2.0)
		
	_create_detonation_fx()
	queue_free()

func _create_detonation_fx() -> void:
	var root = get_parent()
	if not root:
		return
		
	var flash = Line2D.new()
	flash.width = 6.0
	flash.default_color = Color(1.0, 0.6, 0.1, 1.0) if spell_id == "fireball" else Color(1.0, 0.9, 0.4, 1.0)
	var points = PackedVector2Array()
	for i in range(33):
		var angle = i * TAU / 32
		points.append(Vector2(cos(angle), sin(angle)) * splash_radius)
	flash.points = points
	flash.global_position = target_pos
	root.add_child(flash)
	
	var tw = flash.create_tween()
	tw.tween_property(flash, "scale", Vector2(1.25, 1.25), 0.25)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
