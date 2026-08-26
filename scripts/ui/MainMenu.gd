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
@onready var cards_grid: VBoxContainer = $CardsDialog/ScrollContainer/GridContainer
@onready var close_cards_btn: Button = $CardsDialog/CloseCardsButton

@onready var howto_dialog: Panel = $HowToDialog
@onready var close_howto_btn: Button = $HowToDialog/CloseHowToButton

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
		close_cards_btn.pressed.connect(func(): cards_dialog.visible = false)
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

func _on_peer_joined(peer_id: int) -> void:
	if host_dialog.visible:
		host_status_label.text = "Player 2 joined! Launching battle..."

func _on_cards_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	cards_dialog.visible = true
	_populate_card_list()

func _populate_card_list() -> void:
	if not cards_grid:
		return
		
	for child in cards_grid.get_children():
		child.queue_free()
		
	var all_ids = CardDatabase.get_all_card_ids()
	for id in all_ids:
		var data = CardDatabase.get_card(id)
		var card_panel = PanelContainer.new()
		card_panel.custom_minimum_size = Vector2(280, 100)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card_panel.add_child(hbox)
		
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(60, 80)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = TextureGenerator.get_card_icon(id)
		hbox.add_child(icon)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s (%d Elixir - %s)" % [data.get("name", ""), data.get("cost", 3), data.get("rarity", "Common")]
		name_lbl.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = data.get("description", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.8, 0.8, 0.8)
		vbox.add_child(desc_lbl)
		
		var stats_lbl = Label.new()
		stats_lbl.text = "HP: %d | DMG: %d | Range: %d" % [int(data.get("hp", 0)), int(data.get("damage", 0)), int(data.get("range", 0))]
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.modulate = Color(0.4, 0.9, 0.5)
		vbox.add_child(stats_lbl)
		
		cards_grid.add_child(card_panel)

func _on_howto_pressed() -> void:
	SoundManager.play_sfx("card_play", 0.0)
	howto_dialog.visible = true
