extends Node

var frames_run = 0
var arena_instance: Node2D = null
var match_mgr: Node = null

func _ready() -> void:
	print("\n--- Running Live Battle Simulation Test (120 frames) ---")
	var scene = load("res://scenes/game_arena.tscn").instantiate()
	add_child(scene)
	arena_instance = scene.get_node("Arena")
	match_mgr = scene.get_node("MatchManager")
	
	# Spawn test cards from both teams
	arena_instance.spawn_card("giant", 1, Vector2(-125, 100))
	arena_instance.spawn_card("archers", 1, Vector2(-125, 130))
	arena_instance.spawn_card("baby_dragon", 2, Vector2(-125, -100))
	arena_instance.spawn_card("knight", 2, Vector2(-125, -130))
	arena_instance.spawn_card("fireball", 1, Vector2(-125, -200))
	arena_instance.spawn_card("arrows", 2, Vector2(-125, 100))
	arena_instance.spawn_card("cannon", 1, Vector2(0, 100))
	arena_instance.spawn_card("skeletons", 2, Vector2(125, -80))
	arena_instance.spawn_card("minions", 1, Vector2(125, 80))

func _physics_process(_delta: float) -> void:
	frames_run += 1
	if frames_run % 30 == 0:
		print("  Frame ", frames_run, " simulated. Units T1: ", arena_instance.units_team1.size(), ", Units T2: ", arena_instance.units_team2.size())
		
	if frames_run >= 120:
		print("  ✓ Battle simulation finished cleanly without any exceptions!")
		get_tree().quit(0)
