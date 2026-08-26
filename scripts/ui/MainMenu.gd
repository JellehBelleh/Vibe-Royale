extends Control

@onready var solo_btn: Button = $VBoxContainer/SoloButton
@onready var host_btn: Button = $VBoxContainer/HostButton
@onready var join_btn: Button = $VBoxContainer/JoinButton
@onready var cards_btn: Button = $VBoxContainer/CardsButton
@onready var how_to_btn: Button = $VBoxContainer/HowToButton

@onready var join_dialog: Panel = $JoinDialog
@onready var ip_input: LineEdit = $JoinDialog/VBoxContainer/IPInput
@onready var port_input: LineEdit = $JoinDialog/VBoxContainer/PortInput
@onready var connect_btn: Button = $JoinDialog/VBoxContainer/HBoxContainer/ConnectButton
@onready var cancel_join_btn: Button = $JoinDialog/VBoxContainer/HBoxContainer/CancelButton

@onready var host_dialog: Panel = $HostDialog
@onready var host_status_label: Label = $HostDialog/VBoxContainer/StatusLabel
@onready var cancel_host_btn: Button = $HostDialog/VBoxContainer/CancelHostButton

@onready var cards_dialog: Panel = $CardsDialog
@onready var deck_grid: GridContainer = $CardsDialog/MainVBox/DeckGrid
@onready var avg_elixir_label: Label = $CardsDialog/MainVBox/DeckHeader/AvgElixirLabel
@onready var hint_label: Label = $CardsDialog/MainVBox/HintLabel
@onready var reset_deck_btn: Button = $CardsDialog/MainVBox/CollectionHeader/ResetDeckButton
@onready var collection_vbox: VBoxContainer = $CardsDialog/MainVBox/ScrollContainer/CollectionVBox
@onready var close_cards_btn: Button = $CardsDialog/MainVBox/BottomBar/CloseCardsButton

@onready var howto_dialog: Panel = $HowToDialog
@onready var close_howto_btn: Button = $HowToDialog/CloseHowToButton

var selected_deck_slot: int = -1
var selected_collection_id: String = ""

func _ready() -> void:
	if solo_btn:
		solo_btn.pressed.connect(_on_solo_pressed)
	if host_btn:
		host_btn.pressed.connect(_on_host_pressed)
	if join_btn:
		join_btn.pressed.connect(_on_join_pressed)
	if cards_btn:
		cards_btn.pressed.connect(_on_cards_pressed)
	if how_to_btn:
		how_to_btn.pressed.connect(_on_howto_pressed)

	if connect_btn:
		connect_btn.pressed.connect(_on_connect_pressed)
	if cancel_join_btn:
		cancel_join_btn.pressed.connect(func(): join_dialog.visible = false)
	if cancel_host_btn:
		cancel_host_btn.pressed.connect(_on_cancel_host)
	if close_cards_btn:
		close_cards_btn.pressed.connect(func():
			selected_deck_slot = -1
			selected_collection_id = ""
			cards_dialog.visible = false
		)
	if reset_deck_btn:
		reset_deck_btn.pressed.connect(_on_reset_deck_pressed)
	if close_howto_btn:
		close_howto_btn.pressed.connect(func(): howto_dialog.visible = false)

	if join_dialog:
		join_dialog.visible = false
	if host_dialog:
		host_dialog.visible = false
	if cards_dialog:
		cards_dialog.visible = false
	if howto_dialog:
		howto_dialog.visible = false

	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed_signal.connect(_on_connection_failed)
	NetworkManager.peer_joined.connect(_on_peer_joined)

func _on_solo_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	NetworkManager.start_bot_mode()

func _on_host_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	var err = NetworkManager.host_game(7777)
	if err == OK:
		host_dialog.visible = true
		host_status_label.text = "Hosting match on Port 7777...\nWaiting for Player 2 (Connect to 127.0.0.1:7777)..."
	else:
		host_status_label.text = "Failed to host: Error code " + str(err)

func _on_cancel_host() -> void:
	NetworkManager.close_network()
	host_dialog.visible = false

func _on_join_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	join_dialog.visible = true

func _on_connect_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var port = int(port_input.text) if port_input.text != "" else 7777
	
	SoundManager.play_sfx("card_play", 0.0)
	var err = NetworkManager.join_game(ip, port)
	if err == OK:
		connect_btn.text = "Connecting..."
		connect_btn.disabled = true
	else:
		connect_btn.text = "Failed (" + str(err) + ")"
		connect_btn.disabled = false

func _on_connection_succeeded() -> void:
	connect_btn.text = "Connected! Loading arena..."

func _on_connection_failed(reason: String) -> void:
	connect_btn.text = "Connect"
	connect_btn.disabled = false
	join_dialog.get_node("VBoxContainer/ErrorLabel").text = reason

func _on_peer_joined(_peer_id: int) -> void:
	if host_dialog.visible:
		host_status_label.text = "Player 2 joined! Launching battle..."

func _on_cards_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	selected_deck_slot = -1
	selected_collection_id = ""
	cards_dialog.visible = true
	_refresh_deck_ui()

func _on_reset_deck_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	CardDatabase.reset_to_starter_deck()
	selected_deck_slot = -1
	selected_collection_id = ""
	_refresh_deck_ui()

func _refresh_deck_ui() -> void:
	var deck = CardDatabase.get_player_deck()
	
	# Update Average Elixir
	if avg_elixir_label:
		avg_elixir_label.text = "Avg: %.1f 💧" % CardDatabase.get_average_elixir(deck)
		
	# Update Hint Text
	_update_hint_text(deck)
	
	# Build 8 Deck Slots
	_populate_deck_slots(deck)
	
	# Build 10 Collection Cards
	_populate_collection_list(deck)

func _update_hint_text(deck: Array[String]) -> void:
	if not hint_label:
		return
		
	if selected_deck_slot != -1 and selected_deck_slot < deck.size():
		var c_id = deck[selected_deck_slot]
		var c_name = CardDatabase.get_card(c_id).get("name", c_id)
		hint_label.text = "👉 Slot %d [%s] selected! Tap any Collection card below to replace it, or another Deck slot to swap." % [selected_deck_slot + 1, c_name]
		hint_label.modulate = Color(1.0, 0.9, 0.3)
	elif selected_collection_id != "":
		var c_name = CardDatabase.get_card(selected_collection_id).get("name", selected_collection_id)
		hint_label.text = "👉 [%s] selected! Tap any card in your Battle Deck above to place it there." % c_name
		hint_label.modulate = Color(0.4, 0.9, 1.0)
	else:
		hint_label.text = "💡 Tap any card in your Battle Deck or Collection to swap cards."
		hint_label.modulate = Color(0.9, 0.9, 0.95)

func _populate_deck_slots(deck: Array[String]) -> void:
	if not deck_grid:
		return
		
	for child in deck_grid.get_children():
		child.queue_free()
		
	for i in range(CardDatabase.DECK_SIZE):
		var card_id = deck[i] if i < deck.size() else ""
		var card_data = CardDatabase.get_card(card_id)
		var is_selected = (selected_deck_slot == i)
		
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(108, 80)
		slot_btn.focus_mode = Control.FOCUS_NONE
		
		# Custom Stylebox for Slot
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		if is_selected:
			sb.bg_color = Color(0.24, 0.36, 0.58, 1.0)
			sb.border_color = Color(1.0, 0.85, 0.2, 1.0)
			sb.border_width_left = 3
			sb.border_width_top = 3
			sb.border_width_right = 3
			sb.border_width_bottom = 3
			sb.shadow_size = 4
			sb.shadow_color = Color(1.0, 0.85, 0.2, 0.4)
		else:
			sb.bg_color = Color(0.12, 0.15, 0.22, 1.0)
			sb.border_color = Color(0.32, 0.38, 0.48, 1.0)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			
		slot_btn.add_theme_stylebox_override("normal", sb)
		slot_btn.add_theme_stylebox_override("hover", sb)
		slot_btn.add_theme_stylebox_override("pressed", sb)
		
		# Inner Layout
		var margin = MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		slot_btn.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 6)
		margin.add_child(hbox)
		
		# Icon
		var icon = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(40, 56)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if card_id != "":
			icon.texture = TextureGenerator.get_card_icon(card_id)
		hbox.add_child(icon)
		
		# Text info
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)
		
		var cost_lbl = Label.new()
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cost_lbl.text = "%d 💧" % card_data.get("cost", 3)
		cost_lbl.add_theme_font_size_override("font_size", 12)
		cost_lbl.modulate = Color(1.0, 0.4, 0.8)
		vbox.add_child(cost_lbl)
		
		var name_lbl = Label.new()
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.text = card_data.get("name", "Card")
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vbox.add_child(name_lbl)
		
		if is_selected:
			var tag_lbl = Label.new()
			tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tag_lbl.text = "SWAP"
			tag_lbl.add_theme_font_size_override("font_size", 9)
			tag_lbl.modulate = Color(1.0, 0.85, 0.2)
			vbox.add_child(tag_lbl)
		
		slot_btn.pressed.connect(_on_deck_slot_clicked.bind(i))
		deck_grid.add_child(slot_btn)

func _populate_collection_list(deck: Array[String]) -> void:
	if not collection_vbox:
		return
		
	for child in collection_vbox.get_children():
		child.queue_free()
		
	var all_ids = CardDatabase.get_all_card_ids()
	for id in all_ids:
		var data = CardDatabase.get_card(id)
		var is_in_deck = deck.has(id)
		var is_selected_col = (selected_collection_id == id)
		
		var card_panel = PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(0, 78)
		
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 8
		sb.corner_radius_top_right = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_radius_bottom_left = 8
		if is_selected_col:
			sb.bg_color = Color(0.2, 0.35, 0.55, 1.0)
			sb.border_color = Color(0.4, 0.9, 1.0, 1.0)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			sb.shadow_size = 4
			sb.shadow_color = Color(0.3, 0.8, 1.0, 0.4)
		elif is_in_deck:
			sb.bg_color = Color(0.12, 0.16, 0.22, 0.95)
			sb.border_color = Color(0.2, 0.5, 0.35, 0.8)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
		else:
			sb.bg_color = Color(0.16, 0.18, 0.26, 0.98)
			sb.border_color = Color(0.65, 0.5, 0.15, 0.9)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			
		card_panel.add_theme_stylebox_override("panel", sb)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 6)
		card_panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		# Card Icon
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = TextureGenerator.get_card_icon(id)
		hbox.add_child(icon)
		
		# Center Info
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(vbox)
		
		# Title & Rarity
		var rarity = data.get("rarity", "Common")
		var rarity_col = Color(0.85, 0.9, 1.0)
		if rarity == "Rare":
			rarity_col = Color(1.0, 0.65, 0.2)
		elif rarity == "Epic":
			rarity_col = Color(0.9, 0.35, 0.95)
			
		var type_str = "Troop"
		if data.get("is_spell", false):
			type_str = "Spell"
		elif data.get("is_building", false):
			type_str = "Building"
			
		var name_lbl = Label.new()
		name_lbl.text = "%s (%d 💧 - %s) • %s" % [data.get("name", ""), data.get("cost", 3), rarity, type_str]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = rarity_col
		vbox.add_child(name_lbl)
		
		# Stats
		var stats_lbl = Label.new()
		if data.get("is_spell", false):
			stats_lbl.text = "Damage: %d | Radius: %d" % [int(data.get("damage", 0)), int(data.get("splash_radius", 0))]
		elif data.get("is_building", false):
			stats_lbl.text = "HP: %d | DMG: %d | Range: %d | Life: %ds" % [int(data.get("hp", 0)), int(data.get("damage", 0)), int(data.get("range", 0)), int(data.get("building_lifetime", 30))]
		else:
			stats_lbl.text = "HP: %d | DMG: %d | Range: %d | Count: %d" % [int(data.get("hp", 0)), int(data.get("damage", 0)), int(data.get("range", 0)), int(data.get("count", 1))]
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.modulate = Color(0.4, 0.9, 0.5)
		vbox.add_child(stats_lbl)
		
		# Description
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.modulate = Color(0.75, 0.75, 0.8)
		vbox.add_child(desc_lbl)
		
		# Right Action Button / Badge
		var right_box = VBoxContainer.new()
		right_box.custom_minimum_size = Vector2(92, 0)
		right_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(right_box)
		
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(88, 36)
		action_btn.focus_mode = Control.FOCUS_NONE
		
		if is_in_deck:
			action_btn.text = "✔ In Deck"
			action_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
			action_btn.add_theme_font_size_override("font_size", 12)
		else:
			action_btn.text = "⚡ USE" if not is_selected_col else "SELECTED"
			action_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
			action_btn.add_theme_font_size_override("font_size", 12)
			
		action_btn.pressed.connect(_on_collection_card_clicked.bind(id))
		right_box.add_child(action_btn)
		
		# Make the card panel clickable as well
		card_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_collection_card_clicked(id)
		)
		
		collection_vbox.add_child(card_panel)

func _on_deck_slot_clicked(slot_idx: int) -> void:
	SoundManager.play_sfx("card_play", 0.0)
	
	if selected_collection_id != "":
		# User selected a collection card first, then tapped this deck slot
		CardDatabase.swap_deck_card(slot_idx, selected_collection_id)
		selected_collection_id = ""
		selected_deck_slot = -1
	elif selected_deck_slot == slot_idx:
		# Deselect
		selected_deck_slot = -1
	elif selected_deck_slot != -1 and selected_deck_slot != slot_idx:
		# User tapped two deck slots -> swap their positions
		CardDatabase.swap_two_slots(selected_deck_slot, slot_idx)
		selected_deck_slot = -1
	else:
		# Select this deck slot for replacement
		selected_deck_slot = slot_idx
		
	_refresh_deck_ui()

func _on_collection_card_clicked(card_id: String) -> void:
	SoundManager.play_sfx("card_play", 0.0)
	var current_deck = CardDatabase.get_player_deck()
	
	if selected_deck_slot != -1:
		# User tapped a deck slot first, then clicked this collection card -> swap into that slot!
		CardDatabase.swap_deck_card(selected_deck_slot, card_id)
		selected_deck_slot = -1
		selected_collection_id = ""
	else:
		if current_deck.has(card_id):
			# If already in deck, highlight that deck slot
			var idx = current_deck.find(card_id)
			selected_deck_slot = idx
			selected_collection_id = ""
		else:
			# If not in deck, select this collection card
			if selected_collection_id == card_id:
				selected_collection_id = ""
			else:
				selected_collection_id = card_id
				
	_refresh_deck_ui()

func _on_howto_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	howto_dialog.visible = true

