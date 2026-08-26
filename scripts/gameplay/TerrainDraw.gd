extends Node2D

func _draw() -> void:
	var arena = get_parent()
	if arena and arena.has_method("_draw_terrain_canvas"):
		arena._draw_terrain_canvas(self)
