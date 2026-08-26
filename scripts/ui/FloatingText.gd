extends Node2D

@onready var label: Label = $Label

func setup(text: String, pos: Vector2, color: Color = Color.WHITE) -> void:
	global_position = pos
	if not label:
		label = Label.new()
		add_child(label)
		
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 16)
	
	var tw = create_tween()
	tw.tween_property(self, "global_position:y", global_position.y - 25.0, 0.5)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
