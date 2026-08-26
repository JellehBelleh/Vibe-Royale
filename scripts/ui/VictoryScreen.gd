extends Control

@onready var title_label: Label = $Panel/TitleLabel
@onready var score_label: Label = $Panel/ScoreLabel
@onready var rematch_btn: Button = $Panel/RematchButton
@onready var menu_btn: Button = $Panel/MenuButton

func _ready() -> void:
	visible = false
	if rematch_btn:
		rematch_btn.pressed.connect(_on_rematch_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)

func show_result(winner_team: int, team1_crowns: int, team2_crowns: int) -> void:
	visible = true
	var local_team = NetworkManager.local_team
	
	if winner_team == 0:
		title_label.text = "DRAW!"
		title_label.modulate = Color(0.9, 0.9, 0.9)
	elif winner_team == local_team:
		title_label.text = "VICTORY!"
		title_label.modulate = Color(1.0, 0.85, 0.2)
		SoundManager.play_sfx("victory", 2.0)
	else:
		title_label.text = "DEFEAT"
		title_label.modulate = Color(0.95, 0.3, 0.3)
		SoundManager.play_sfx("defeat", 2.0)
		
	var my_crowns = team1_crowns if local_team == 1 else team2_crowns
	var enemy_crowns = team2_crowns if local_team == 1 else team1_crowns
	score_label.text = str(my_crowns) + " - " + str(enemy_crowns)
	
	# Animate popup
	scale = Vector2(0.5, 0.5)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_rematch_pressed() -> void:
	if NetworkManager.is_bot_mode:
		get_tree().reload_current_scene()
	elif NetworkManager.is_host:
		NetworkManager.rpc("sync_start_match")
		get_tree().reload_current_scene()
	else:
		get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	NetworkManager.close_network()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
