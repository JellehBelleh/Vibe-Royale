extends Node2D

var is_active: bool = false
var is_spell: bool = false
var team: int = 1

func set_dropzone(p_active: bool, p_spell: bool, p_team: int) -> void:
	is_active = p_active
	is_spell = p_spell
	team = p_team
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
		
	var arena = get_parent()
	if not arena:
		return
		
	var w = arena.ARENA_WIDTH - 30.0
	var h = arena.ARENA_HEIGHT - 40.0
	
	if is_spell:
		# Full arena glow for global spells (Fireball, Arrows)
		draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), Color(0.2, 0.8, 1.0, 0.12), true)
		draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), Color(0.2, 0.8, 1.0, 0.6), false, 2.0)
	else:
		# Home Base Territory: always bottom half (Y >= 25)
		var zone_h = (h / 2.0) - 25.0
		draw_rect(Rect2(-w / 2.0, 25.0, w, zone_h), Color(0.2, 0.9, 0.4, 0.15), true)
		draw_rect(Rect2(-w / 2.0, 25.0, w, zone_h), Color(0.2, 0.9, 0.4, 0.7), false, 2.0)
		
		# Territory expansion if enemy princess towers are destroyed
		var enemy_towers = arena.towers_team2 if NetworkManager.local_team == 1 else arena.towers_team1
		var left_key = "princess_left" if NetworkManager.local_team == 1 else "princess_right"
		var right_key = "princess_right" if NetworkManager.local_team == 1 else "princess_left"
		
		var left_dead = not enemy_towers.has(left_key) or enemy_towers[left_key].is_dead
		var right_dead = not enemy_towers.has(right_key) or enemy_towers[right_key].is_dead
		
		if left_dead:
			draw_rect(Rect2(-w / 2.0, -130.0, w / 2.0, 155.0), Color(0.2, 0.9, 0.4, 0.12), true)
		if right_dead:
			draw_rect(Rect2(0, -130.0, w / 2.0, 155.0), Color(0.2, 0.9, 0.4, 0.12), true)
