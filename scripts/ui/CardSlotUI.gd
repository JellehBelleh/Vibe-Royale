extends Control

signal card_clicked(card_id: String, slot_idx: int)

@export var slot_index: int = 0
var card_id: String = ""
var is_affordable: bool = true
var is_selected: bool = false
var is_hovered: bool = false

@onready var icon_rect: TextureRect = $IconRect
@onready var cost_label: Label = $CostBubble/CostLabel
@onready var name_label: Label = $NameLabel
@onready var shade: ColorRect = $Shade
@onready var highlight: ReferenceRect = $Highlight

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Make sure all children ignore mouse so root gets clicks
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for subchild in child.get_children():
			if subchild is Control:
				subchild.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_card(new_card_id: String) -> void:
	card_id = new_card_id
	var card_data = CardDatabase.get_card(card_id)
	if card_data.is_empty():
		visible = false
		return
		
	visible = true
	if icon_rect:
		icon_rect.texture = TextureGenerator.get_card_icon(card_id)
	if cost_label:
		cost_label.text = str(card_data.get("cost", 3))
	if name_label:
		name_label.text = card_data.get("name", "")

func update_elixir(current_elixir: float) -> void:
	if card_id == "":
		return
	var card_data = CardDatabase.get_card(card_id)
	var cost = card_data.get("cost", 3)
	is_affordable = current_elixir >= cost
	
	if shade:
		shade.visible = not is_affordable

func set_selected(selected: bool) -> void:
	is_selected = selected
	if highlight:
		highlight.visible = selected
	_update_transform()

func _update_transform() -> void:
	if is_selected:
		scale = Vector2(1.12, 1.12)
		modulate = Color(1.1, 1.1, 1.1)
	elif is_hovered and is_affordable:
		scale = Vector2(1.05, 1.05)
		modulate = Color(1.05, 1.05, 1.05)
	else:
		scale = Vector2(1.0, 1.0)
		modulate = Color(1.0, 1.0, 1.0)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_transform()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_transform()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_affordable and card_id != "":
			SoundManager.play_sfx("card_play", 0.0)
			card_clicked.emit(card_id, slot_index)
