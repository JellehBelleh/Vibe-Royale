extends CanvasLayer

var selected_card_id: String = ""
var selected_slot_idx: int = -1
var current_elixir: float = 5.0

@onready var match_manager: Node = get_parent().get_node("MatchManager")
@onready var arena: Node2D = get_parent().get_node("Arena")
@onready var drop_zone_overlay: Node2D = get_parent().get_node_or_null("Arena/DropZoneOverlay")

# UI Elements
@onready var timer_label: Label = $TopBar/TimerContainer/TimerLabel
@onready var blue_crowns_label: Label = $TopBar/CrownsContainer/BlueCrownsLabel
@onready var red_crowns_label: Label = $TopBar/CrownsContainer/RedCrownsLabel
@onready var banner_label: Label = $BannerLabel

# Elixir Elements
@onready var elixir_bar: ProgressBar = $BottomDock/ElixirContainer/ElixirBar
@onready var elixir_label: Label = $BottomDock/ElixirContainer/ElixirLabel
@onready var elixir_icon: TextureRect = $BottomDock/ElixirContainer/ElixirIcon

# Card Hand Slots
@onready var slot_0: Control = $BottomDock/HandContainer/Slot0
@onready var slot_1: Control = $BottomDock/HandContainer/Slot1
@onready var slot_2: Control = $BottomDock/HandContainer/Slot2
@onready var slot_3: Control = $BottomDock/HandContainer/Slot3
@onready var next_slot: Control = $BottomDock/NextContainer/NextSlot

# Placement Preview
@onready var placement_preview: Node2D = $PlacementPreview
@onready var preview_circle: Line2D = $PlacementPreview/PreviewCircle
@onready var preview_sprite: Sprite2D = $PlacementPreview/PreviewSprite

# Victory Screen
@onready var victory_screen: Control = $VictoryScreen

var slots: Array[Control] = []

func _ready() -> void:
	slots = [slot_0, slot_1, slot_2, slot_3]
	
	for i in range(slots.size()):
		if slots[i]:
			slots[i].slot_index = i
			slots[i].card_clicked.connect(_on_card_slot_clicked)
			
	if elixir_icon:
		elixir_icon.texture = TextureGenerator.get_elixir_drop_texture()

	# Connect signals from MatchManager
	if match_manager:
		match_manager.match_time_updated.connect(_on_time_updated)
		match_manager.elixir_updated.connect(_on_elixir_updated)
		match_manager.hand_updated.connect(_on_hand_updated)
		match_manager.crowns_updated.connect(_on_crowns_updated)
		match_manager.game_over_signal.connect(_on_game_over)
		match_manager.banner_message.connect(_on_banner_message)

		# Immediate initial HUD sync
		_sync_initial_hud_state()

	if banner_label:
		banner_label.visible = false

func _sync_initial_hud_state() -> void:
	var my_team = NetworkManager.local_team
	var hand = match_manager.get_hand_for_team(my_team)
	var next_card = match_manager.get_next_for_team(my_team)
	var elixir = match_manager.get_elixir_for_team(my_team)
	
	_on_hand_updated(my_team, hand, next_card)
	_on_elixir_updated(my_team, elixir)

func _on_card_slot_clicked(card_id: String, slot_idx: int) -> void:
	if selected_slot_idx == slot_idx:
		_clear_selection()
	else:
		selected_card_id = card_id
		selected_slot_idx = slot_idx
		for i in range(slots.size()):
			if slots[i]:
				slots[i].set_selected(i == slot_idx)
		_update_preview_visuals()

func _clear_selection() -> void:
	selected_card_id = ""
	selected_slot_idx = -1
	for s in slots:
		if s:
			s.set_selected(false)
	if placement_preview:
		placement_preview.visible = false
	if drop_zone_overlay and drop_zone_overlay.has_method("set_dropzone"):
		drop_zone_overlay.set_dropzone(false, false, NetworkManager.local_team)

func _update_preview_visuals() -> void:
	if selected_card_id == "" or not placement_preview:
		if placement_preview:
			placement_preview.visible = false
		if drop_zone_overlay and drop_zone_overlay.has_method("set_dropzone"):
			drop_zone_overlay.set_dropzone(false, false, NetworkManager.local_team)
		return
		
	placement_preview.visible = true
	var card_data = CardDatabase.get_card(selected_card_id)
	var is_spell = card_data.get("is_spell", false)
	var radius = card_data.get("splash_radius", 0.0)
	if radius <= 0.0:
		radius = card_data.get("range", 35.0)
		
	# Draw preview circle
	var points = PackedVector2Array()
	var segs = 32
	for i in range(segs + 1):
		var angle = i * TAU / segs
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	preview_circle.points = points
	preview_circle.default_color = Color(1.0, 0.4, 0.2, 0.7) if is_spell else Color(0.3, 0.8, 1.0, 0.7)
	
	# Preview icon
	if preview_sprite:
		preview_sprite.texture = TextureGenerator.get_unit_texture(selected_card_id, NetworkManager.local_team)
		preview_sprite.modulate = Color(1, 1, 1, 0.75)
		
	# Update drop zone visual
	if drop_zone_overlay and drop_zone_overlay.has_method("set_dropzone"):
		drop_zone_overlay.set_dropzone(true, is_spell, NetworkManager.local_team)

func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1, 2, 3, 4 shortcut for hand slots
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_select_slot_by_index(0)
		elif event.keycode == KEY_2:
			_select_slot_by_index(1)
		elif event.keycode == KEY_3:
			_select_slot_by_index(2)
		elif event.keycode == KEY_4:
			_select_slot_by_index(3)
		elif event.keycode == KEY_ESCAPE:
			_clear_selection()

	# Mouse placement
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_clear_selection()
		elif event.button_index == MOUSE_BUTTON_LEFT and selected_card_id != "":
			var world_pos = arena.get_global_mouse_position()
			var card_data = CardDatabase.get_card(selected_card_id)
			var is_spell = card_data.get("is_spell", false)
			
			if arena.is_valid_deployment(world_pos, NetworkManager.local_team, is_spell):
				var success = match_manager.try_play_card_local(selected_card_id, world_pos)
				if success:
					_clear_selection()

func _select_slot_by_index(idx: int) -> void:
	if idx >= 0 and idx < slots.size() and slots[idx]:
		var slot = slots[idx]
		if slot.is_affordable and slot.card_id != "":
			_on_card_slot_clicked(slot.card_id, idx)

func _process(_delta: float) -> void:
	if selected_card_id != "" and placement_preview and arena:
		placement_preview.global_position = get_viewport().get_mouse_position()
		
		var world_pos = arena.get_global_mouse_position()
		var card_data = CardDatabase.get_card(selected_card_id)
		var is_spell = card_data.get("is_spell", false)
		var is_valid = arena.is_valid_deployment(world_pos, NetworkManager.local_team, is_spell)
		
		preview_circle.default_color = Color(0.2, 0.9, 0.4, 0.8) if is_valid else Color(0.95, 0.2, 0.2, 0.8)

# --- SIGNAL HANDLERS ---

func _on_time_updated(time_left: float, _phase: int) -> void:
	if timer_label:
		var mins = int(time_left / 60.0)
		var secs = int(time_left) % 60
		timer_label.text = "%d:%02d" % [mins, secs]
		if time_left <= 30.0:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			timer_label.modulate = Color(1.0, 1.0, 1.0)

func _on_elixir_updated(team: int, elixir: float) -> void:
	if team == NetworkManager.local_team:
		current_elixir = elixir
		if elixir_bar:
			elixir_bar.value = elixir
		if elixir_label:
			elixir_label.text = str(int(elixir)) + " / 10"
			
		for s in slots:
			if s:
				s.update_elixir(elixir)

func _on_hand_updated(team: int, hand: Array, next_card: String) -> void:
	if team == NetworkManager.local_team:
		for i in range(min(slots.size(), hand.size())):
			if slots[i]:
				slots[i].set_card(hand[i])
				slots[i].update_elixir(current_elixir)
				
		if next_slot:
			next_slot.set_card(next_card)

func _on_crowns_updated(t1: int, t2: int) -> void:
	if blue_crowns_label:
		blue_crowns_label.text = str(t1)
	if red_crowns_label:
		red_crowns_label.text = str(t2)

func _on_banner_message(msg: String) -> void:
	if banner_label:
		banner_label.text = msg
		banner_label.visible = true
		banner_label.scale = Vector2(0.5, 0.5)
		var tw = create_tween()
		tw.tween_property(banner_label, "scale", Vector2(1.2, 1.2), 0.25)
		tw.tween_property(banner_label, "scale", Vector2(1.0, 1.0), 0.15)
		tw.tween_interval(2.0)
		tw.tween_property(banner_label, "modulate:a", 0.0, 0.5)
		tw.tween_callback(func(): banner_label.visible = false; banner_label.modulate.a = 1.0)

func _on_game_over(winner_team: int, t1_crowns: int, t2_crowns: int) -> void:
	_clear_selection()
	if victory_screen:
		victory_screen.show_result(winner_team, t1_crowns, t2_crowns)
