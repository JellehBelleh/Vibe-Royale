extends Node

# Card types
enum CardType {
	TROOP,
	SPELL,
	BUILDING
}

# Target filters
enum TargetType {
	GROUND,
	GROUND_AND_AIR,
	BUILDINGS_ONLY
}

# Speed tiers
const SPEED_SLOW: float = 38.0
const SPEED_MEDIUM: float = 58.0
const SPEED_FAST: float = 85.0
const SPEED_VERY_FAST: float = 110.0

const DECK_SIZE: int = 8
const SAVE_PATH: String = "user://player_deck.json"

signal deck_changed(new_deck: Array)

var cards: Dictionary = {}
var active_deck: Array[String] = []

func _init() -> void:
	_register_all_cards()
	active_deck = load_player_deck()

func _register_all_cards() -> void:
	# 1. KNIGHT - Tough Melee Fighter
	cards["knight"] = {
		"id": "knight",
		"name": "Knight",
		"cost": 3,
		"rarity": "Common",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND,
		"hp": 1400.0,
		"damage": 160.0,
		"hit_speed": 1.2,
		"move_speed": SPEED_MEDIUM,
		"range": 32.0,
		"splash_radius": 0.0,
		"count": 1,
		"is_flying": false,
		"is_spell": false,
		"is_building": false,
		"description": "A tough melee fighter. The handsome, cultured cousin of the Barbarian.",
		"color": Color(0.3, 0.6, 0.95),
		"crown_mult": 1.0
	}

	# 2. ARCHERS - Duo Ranged Sharpshooters
	cards["archers"] = {
		"id": "archers",
		"name": "Archers",
		"cost": 3,
		"rarity": "Common",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 260.0,
		"damage": 90.0,
		"hit_speed": 1.1,
		"move_speed": SPEED_MEDIUM,
		"range": 160.0,
		"splash_radius": 0.0,
		"count": 2,
		"is_flying": false,
		"is_spell": false,
		"is_building": false,
		"description": "A pair of unarmored ranged attackers. They'll help you take down ground and air units.",
		"color": Color(0.9, 0.4, 0.7),
		"crown_mult": 1.0
	}

	# 3. GIANT - Massive Building Targeter
	cards["giant"] = {
		"id": "giant",
		"name": "Giant",
		"cost": 5,
		"rarity": "Rare",
		"type": CardType.TROOP,
		"target_type": TargetType.BUILDINGS_ONLY,
		"hp": 3400.0,
		"damage": 220.0,
		"hit_speed": 1.5,
		"move_speed": SPEED_SLOW,
		"range": 36.0,
		"splash_radius": 0.0,
		"count": 1,
		"is_flying": false,
		"is_spell": false,
		"is_building": false,
		"description": "Slow but durable, only attacks buildings. A real one-man wrecking crew!",
		"color": Color(0.85, 0.55, 0.2),
		"crown_mult": 1.0
	}

	# 4. MUSKETEER - High Range Single-Target Sniper
	cards["musketeer"] = {
		"id": "musketeer",
		"name": "Musketeer",
		"cost": 4,
		"rarity": "Rare",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 600.0,
		"damage": 180.0,
		"hit_speed": 1.0,
		"move_speed": SPEED_MEDIUM,
		"range": 200.0,
		"splash_radius": 0.0,
		"count": 1,
		"is_flying": false,
		"is_spell": false,
		"is_building": false,
		"description": "Don't be fooled by these delicately coiffed purple bangs, the Musketeer is lethal.",
		"color": Color(0.75, 0.35, 0.85),
		"crown_mult": 1.0
	}

	# 5. BABY DRAGON - Flying Splash Dealer
	cards["baby_dragon"] = {
		"id": "baby_dragon",
		"name": "Baby Dragon",
		"cost": 4,
		"rarity": "Epic",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 1050.0,
		"damage": 135.0,
		"hit_speed": 1.4,
		"move_speed": SPEED_FAST,
		"range": 125.0,
		"splash_radius": 45.0,
		"count": 1,
		"is_flying": true,
		"is_spell": false,
		"is_building": false,
		"description": "Flying troop that deals area damage. Baby dragons are cute, full of fire, and hungry.",
		"color": Color(0.3, 0.85, 0.35),
		"crown_mult": 1.0
	}

	# 6. SKELETONS - Fast 4-Count Distraction Swarm
	cards["skeletons"] = {
		"id": "skeletons",
		"name": "Skeletons",
		"cost": 1,
		"rarity": "Common",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND,
		"hp": 80.0,
		"damage": 70.0,
		"hit_speed": 1.0,
		"move_speed": SPEED_FAST,
		"range": 24.0,
		"splash_radius": 0.0,
		"count": 4,
		"is_flying": false,
		"is_spell": false,
		"is_building": false,
		"description": "Four fast, very weak melee fighters. Swarm your enemies with this pile of bones!",
		"color": Color(0.9, 0.9, 0.95),
		"crown_mult": 1.0
	}

	# 7. MINIONS - Fast 3-Pack Flying Swarm
	cards["minions"] = {
		"id": "minions",
		"name": "Minions",
		"cost": 3,
		"rarity": "Common",
		"type": CardType.TROOP,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 190.0,
		"damage": 90.0,
		"hit_speed": 1.0,
		"move_speed": SPEED_FAST,
		"range": 60.0,
		"splash_radius": 0.0,
		"count": 3,
		"is_flying": true,
		"is_spell": false,
		"is_building": false,
		"description": "Three fast, unarmored flying attackers. Roses are red, minions are blue.",
		"color": Color(0.2, 0.7, 0.9),
		"crown_mult": 1.0
	}

	# 8. FIREBALL - Heavy AOE Direct Damage Spell
	cards["fireball"] = {
		"id": "fireball",
		"name": "Fireball",
		"cost": 4,
		"rarity": "Rare",
		"type": CardType.SPELL,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 0.0,
		"damage": 570.0,
		"hit_speed": 0.0,
		"move_speed": 0.0,
		"range": 0.0,
		"splash_radius": 75.0,
		"count": 1,
		"is_flying": false,
		"is_spell": true,
		"is_building": false,
		"description": "Annnnd... Fireball! Incinerates a small area, dealing high damage. Reduced crown tower damage.",
		"color": Color(1.0, 0.45, 0.1),
		"crown_mult": 0.35
	}

	# 9. ARROWS - Wide Swarm Clearing Spell
	cards["arrows"] = {
		"id": "arrows",
		"name": "Arrows",
		"cost": 3,
		"rarity": "Common",
		"type": CardType.SPELL,
		"target_type": TargetType.GROUND_AND_AIR,
		"hp": 0.0,
		"damage": 300.0,
		"hit_speed": 0.0,
		"move_speed": 0.0,
		"range": 0.0,
		"splash_radius": 120.0,
		"count": 1,
		"is_flying": false,
		"is_spell": true,
		"is_building": false,
		"description": "Arrows pepper a large area, damaging all enemies hit. Great against swarms!",
		"color": Color(0.95, 0.8, 0.25),
		"crown_mult": 0.35
	}

	# 10. CANNON - Ground Defensive Turret
	cards["cannon"] = {
		"id": "cannon",
		"name": "Cannon",
		"cost": 3,
		"rarity": "Common",
		"type": CardType.BUILDING,
		"target_type": TargetType.GROUND,
		"hp": 750.0,
		"damage": 130.0,
		"hit_speed": 0.8,
		"move_speed": 0.0,
		"range": 170.0,
		"splash_radius": 0.0,
		"count": 1,
		"is_flying": false,
		"is_spell": false,
		"is_building": true,
		"building_lifetime": 30.0,
		"description": "Defensive building. Shoots cannonballs at ground enemies. Has a 30s lifetime.",
		"color": Color(0.5, 0.45, 0.4),
		"crown_mult": 1.0
	}

func get_card(card_id: String) -> Dictionary:
	if cards.has(card_id):
		return cards[card_id]
	return {}

func get_all_card_ids() -> Array[String]:
	var list: Array[String] = []
	for key in cards.keys():
		list.append(str(key))
	return list

func get_starter_deck() -> Array[String]:
	return [
		"knight",
		"archers",
		"giant",
		"musketeer",
		"baby_dragon",
		"skeletons",
		"fireball",
		"arrows"
	]

func is_valid_deck(deck: Array) -> bool:
	if deck.size() != DECK_SIZE:
		return false
	var seen: Dictionary = {}
	for card_id in deck:
		var s_id = str(card_id)
		if not cards.has(s_id) or seen.has(s_id):
			return false
		seen[s_id] = true
	return true

func get_player_deck() -> Array[String]:
	if not is_valid_deck(active_deck):
		active_deck = load_player_deck()
	var copy: Array[String] = []
	for id in active_deck:
		copy.append(str(id))
	return copy

func set_player_deck(new_deck: Array) -> bool:
	if not is_valid_deck(new_deck):
		return false
	active_deck.clear()
	for id in new_deck:
		active_deck.append(str(id))
	save_player_deck()
	deck_changed.emit(active_deck.duplicate())
	return true

func swap_deck_card(slot_idx: int, new_card_id: String) -> bool:
	if slot_idx < 0 or slot_idx >= DECK_SIZE:
		return false
	if not cards.has(new_card_id):
		return false
	if not is_valid_deck(active_deck):
		active_deck = get_starter_deck()

	var existing_idx = active_deck.find(new_card_id)
	if existing_idx != -1:
		# If the card is already in the deck, swap the two slot positions
		var temp = active_deck[slot_idx]
		active_deck[slot_idx] = new_card_id
		active_deck[existing_idx] = temp
	else:
		# Replace the card at slot_idx
		active_deck[slot_idx] = new_card_id

	save_player_deck()
	deck_changed.emit(active_deck.duplicate())
	return true

func swap_two_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= DECK_SIZE or slot_b < 0 or slot_b >= DECK_SIZE:
		return false
	if not is_valid_deck(active_deck):
		active_deck = get_starter_deck()
		
	var temp = active_deck[slot_a]
	active_deck[slot_a] = active_deck[slot_b]
	active_deck[slot_b] = temp
	save_player_deck()
	deck_changed.emit(active_deck.duplicate())
	return true

func reset_to_starter_deck() -> void:
	active_deck = get_starter_deck()
	save_player_deck()
	deck_changed.emit(active_deck.duplicate())

func get_average_elixir(deck: Array = []) -> float:
	var target = deck if deck.size() > 0 else active_deck
	if target.size() == 0:
		return 0.0
	var total: float = 0.0
	for id in target:
		var c = get_card(str(id))
		total += float(c.get("cost", 3))
	return snappedf(total / float(target.size()), 0.1)

func save_player_deck() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"deck": active_deck
		}
		file.store_string(JSON.stringify(data))
		file.close()

func load_player_deck() -> Array[String]:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary and parsed.has("deck") and parsed["deck"] is Array:
				if is_valid_deck(parsed["deck"]):
					var result: Array[String] = []
					for id in parsed["deck"]:
						result.append(str(id))
					return result
	return get_starter_deck()
