extends Node

var texture_cache: Dictionary = {}

func get_color_for_team(team: int) -> Color:
	if team == 1:
		return Color(0.2, 0.55, 0.95) # Vibrant Blue (Player 1)
	else:
		return Color(0.95, 0.25, 0.3) # Vibrant Red (Player 2)

func get_team_dark_color(team: int) -> Color:
	if team == 1:
		return Color(0.1, 0.25, 0.5)
	else:
		return Color(0.5, 0.1, 0.15)

# --- CACHED TEXTURE GENERATION ---

func get_unit_texture(unit_id: String, team: int) -> Texture2D:
	var key = "unit_" + unit_id + "_" + str(team)
	if texture_cache.has(key):
		return texture_cache[key]
	
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var team_col = get_color_for_team(team)
	var dark_team = get_team_dark_color(team)
	
	match unit_id:
		"knight":
			# Body / Armor
			_draw_filled_circle(img, Vector2i(32, 34), 20, Color(0.65, 0.68, 0.72))
			_draw_filled_circle(img, Vector2i(32, 34), 16, team_col)
			# Head / Helmet
			_draw_filled_circle(img, Vector2i(32, 20), 12, Color(0.75, 0.78, 0.82))
			# Helmet plume
			_draw_filled_circle(img, Vector2i(32, 11), 6, dark_team)
			# Visor slit
			_draw_rect(img, Rect2i(27, 19, 10, 3), Color(0.15, 0.15, 0.18))
			# Sword
			_draw_rect(img, Rect2i(46, 12, 5, 24), Color(0.9, 0.92, 0.95))
			_draw_rect(img, Rect2i(43, 24, 11, 4), Color(0.85, 0.7, 0.2))
			# Shield
			_draw_filled_circle(img, Vector2i(18, 34), 10, Color(0.85, 0.7, 0.2))
			_draw_filled_circle(img, Vector2i(18, 34), 7, dark_team)

		"archers":
			# Cape / Body
			_draw_filled_circle(img, Vector2i(32, 36), 16, Color(0.25, 0.65, 0.35))
			_draw_filled_circle(img, Vector2i(32, 36), 12, team_col)
			# Pink Hair
			_draw_filled_circle(img, Vector2i(32, 20), 13, Color(0.95, 0.4, 0.7))
			# Face
			_draw_filled_circle(img, Vector2i(32, 22), 9, Color(0.98, 0.85, 0.75))
			# Eyes
			_draw_rect(img, Rect2i(29, 20, 2, 3), Color(0.15, 0.15, 0.2))
			_draw_rect(img, Rect2i(33, 20, 2, 3), Color(0.15, 0.15, 0.2))
			# Bow
			_draw_arc(img, Vector2i(45, 32), 12, Color(0.55, 0.35, 0.15))

		"giant":
			# Huge Body
			_draw_filled_circle(img, Vector2i(32, 36), 24, Color(0.55, 0.38, 0.22))
			_draw_filled_circle(img, Vector2i(32, 36), 18, team_col)
			# Head
			_draw_filled_circle(img, Vector2i(32, 16), 14, Color(0.92, 0.75, 0.6))
			# Orange Beard
			_draw_filled_circle(img, Vector2i(32, 22), 10, Color(0.95, 0.5, 0.1))
			# Face
			_draw_filled_circle(img, Vector2i(32, 16), 9, Color(0.92, 0.75, 0.6))
			# Massive Fists
			_draw_filled_circle(img, Vector2i(10, 36), 8, Color(0.88, 0.7, 0.55))
			_draw_filled_circle(img, Vector2i(54, 36), 8, Color(0.88, 0.7, 0.55))

		"musketeer":
			# Coat
			_draw_filled_circle(img, Vector2i(32, 36), 16, team_col)
			# Purple Hair / Hat
			_draw_filled_circle(img, Vector2i(32, 18), 13, Color(0.5, 0.2, 0.65))
			# Hat brim & Feather
			_draw_rect(img, Rect2i(18, 17, 28, 5), Color(0.4, 0.15, 0.55))
			_draw_filled_circle(img, Vector2i(22, 12), 6, Color(0.95, 0.85, 0.3))
			# Face
			_draw_filled_circle(img, Vector2i(32, 22), 8, Color(0.98, 0.85, 0.75))
			# Musket
			_draw_rect(img, Rect2i(42, 10, 6, 36), Color(0.3, 0.3, 0.35))
			_draw_rect(img, Rect2i(41, 30, 8, 12), Color(0.5, 0.3, 0.15))

		"baby_dragon":
			# Dragon Body (Green)
			_draw_filled_circle(img, Vector2i(32, 34), 18, Color(0.3, 0.8, 0.35))
			# Orange Belly
			_draw_filled_circle(img, Vector2i(32, 36), 12, Color(0.95, 0.65, 0.2))
			# Team Col Collar
			_draw_filled_circle(img, Vector2i(32, 22), 10, team_col)
			# Head
			_draw_filled_circle(img, Vector2i(32, 18), 12, Color(0.35, 0.85, 0.4))
			# Cute Eyes
			_draw_filled_circle(img, Vector2i(27, 16), 4, Color(1, 1, 1))
			_draw_filled_circle(img, Vector2i(37, 16), 4, Color(1, 1, 1))
			_draw_filled_circle(img, Vector2i(27, 16), 2, Color(0, 0, 0))
			_draw_filled_circle(img, Vector2i(37, 16), 2, Color(0, 0, 0))
			# Wings
			_draw_filled_circle(img, Vector2i(14, 28), 10, Color(0.95, 0.55, 0.2))
			_draw_filled_circle(img, Vector2i(50, 28), 10, Color(0.95, 0.55, 0.2))

		"skeletons":
			# Bone Body
			_draw_filled_circle(img, Vector2i(32, 36), 12, Color(0.9, 0.9, 0.95))
			_draw_rect(img, Rect2i(28, 32, 8, 10), team_col)
			# Skull
			_draw_filled_circle(img, Vector2i(32, 20), 10, Color(0.95, 0.95, 0.98))
			# Dark Eye Sockets
			_draw_filled_circle(img, Vector2i(28, 19), 3, Color(0.1, 0.1, 0.15))
			_draw_filled_circle(img, Vector2i(36, 19), 3, Color(0.1, 0.1, 0.15))
			# Mini Sword
			_draw_rect(img, Rect2i(42, 16, 4, 20), Color(0.75, 0.8, 0.85))

		"minions":
			# Gargoyle Body (Blue)
			_draw_filled_circle(img, Vector2i(32, 34), 14, Color(0.2, 0.6, 0.85))
			# Wings
			_draw_filled_circle(img, Vector2i(14, 26), 9, Color(0.4, 0.2, 0.6))
			_draw_filled_circle(img, Vector2i(50, 26), 9, Color(0.4, 0.2, 0.6))
			# Head
			_draw_filled_circle(img, Vector2i(32, 20), 10, Color(0.25, 0.65, 0.9))
			# Glowing Eyes
			_draw_filled_circle(img, Vector2i(28, 19), 3, Color(1, 0.9, 0.2))
			_draw_filled_circle(img, Vector2i(36, 19), 3, Color(1, 0.9, 0.2))
			# Horns
			_draw_rect(img, Rect2i(24, 10, 3, 7), Color(0.3, 0.1, 0.4))
			_draw_rect(img, Rect2i(37, 10, 3, 7), Color(0.3, 0.1, 0.4))
			# Team indicator
			_draw_filled_circle(img, Vector2i(32, 36), 6, team_col)

		"cannon":
			# Wooden Platform
			_draw_filled_circle(img, Vector2i(32, 36), 20, Color(0.5, 0.35, 0.2))
			_draw_filled_circle(img, Vector2i(32, 36), 16, Color(0.35, 0.25, 0.15))
			# Team Rim
			_draw_filled_circle(img, Vector2i(32, 36), 12, team_col)
			# Iron Barrel
			_draw_rect(img, Rect2i(26, 12, 12, 30), Color(0.25, 0.27, 0.3))
			_draw_rect(img, Rect2i(24, 10, 16, 5), Color(0.15, 0.17, 0.2))
		
		"fireball":
			_draw_filled_circle(img, Vector2i(32, 32), 22, Color(1, 0.4, 0.05))
			_draw_filled_circle(img, Vector2i(32, 32), 16, Color(1, 0.8, 0.1))
			_draw_filled_circle(img, Vector2i(32, 32), 8, Color(1, 1, 0.9))

		"arrows":
			for i in range(3):
				var ax = 20 + i * 12
				var ay = 18 + (i % 2) * 8
				_draw_rect(img, Rect2i(ax, ay, 4, 28), Color(0.8, 0.6, 0.2))
				_draw_rect(img, Rect2i(ax - 2, ay - 4, 8, 6), Color(0.9, 0.95, 1))

	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func get_tower_texture(tower_type: String, team: int, is_king_active: bool = true) -> Texture2D:
	var key = "tower_" + tower_type + "_" + str(team) + "_" + str(is_king_active)
	if texture_cache.has(key):
		return texture_cache[key]
	
	var team_col = get_color_for_team(team)
	var dark_team = get_team_dark_color(team)
	
	if tower_type == "king":
		var img = Image.create(96, 96, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		# Base Stone Fortress
		_draw_rect(img, Rect2i(16, 26, 64, 60), Color(0.48, 0.52, 0.58))
		_draw_rect(img, Rect2i(20, 30, 56, 52), Color(0.38, 0.42, 0.48))
		# Corner turrets
		_draw_rect(img, Rect2i(12, 22, 16, 64), Color(0.52, 0.56, 0.62))
		_draw_rect(img, Rect2i(68, 22, 16, 64), Color(0.52, 0.56, 0.62))
		# Team Royal Banners
		_draw_rect(img, Rect2i(32, 36, 32, 38), team_col)
		_draw_rect(img, Rect2i(36, 40, 24, 30), dark_team)
		# Golden Crown Insignia
		_draw_filled_circle(img, Vector2i(48, 52), 8, Color(0.95, 0.8, 0.2))
		# Roof / Battlements
		_draw_rect(img, Rect2i(10, 18, 76, 10), Color(0.6, 0.64, 0.7))
		for x in [12, 28, 44, 60, 74]:
			_draw_rect(img, Rect2i(x, 12, 10, 8), Color(0.65, 0.69, 0.75))
		# King / Cannon atop
		if is_king_active:
			# King popping up with crown
			_draw_filled_circle(img, Vector2i(48, 14), 10, Color(0.95, 0.8, 0.65))
			# Golden Crown
			_draw_rect(img, Rect2i(40, 6, 16, 6), Color(0.98, 0.82, 0.15))
			# Big Cannon
			_draw_rect(img, Rect2i(44, 18, 8, 16), Color(0.2, 0.22, 0.25))
		else:
			# Sleeping / Idle King
			_draw_filled_circle(img, Vector2i(48, 16), 8, Color(0.85, 0.7, 0.55))
			_draw_rect(img, Rect2i(42, 10, 12, 5), Color(0.9, 0.75, 0.2))

		var tex = ImageTexture.create_from_image(img)
		texture_cache[key] = tex
		return tex

	else: # princess
		var img = Image.create(72, 84, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		# Stone Turret Base
		_draw_rect(img, Rect2i(16, 28, 40, 50), Color(0.5, 0.54, 0.6))
		_draw_rect(img, Rect2i(20, 32, 32, 42), Color(0.4, 0.44, 0.5))
		# Team Color Trim
		_draw_rect(img, Rect2i(24, 40, 24, 24), team_col)
		# Battlements
		_draw_rect(img, Rect2i(12, 22, 48, 8), Color(0.6, 0.64, 0.7))
		for x in [14, 28, 42, 54]:
			_draw_rect(img, Rect2i(x, 16, 6, 8), Color(0.65, 0.69, 0.75))
		# Princess Top
		_draw_filled_circle(img, Vector2i(36, 16), 8, Color(0.98, 0.85, 0.75))
		_draw_filled_circle(img, Vector2i(36, 12), 7, Color(0.9, 0.35, 0.65)) # Bow / Hair
		# Bow
		_draw_arc(img, Vector2i(36, 14), 10, Color(0.5, 0.3, 0.15))

		var tex = ImageTexture.create_from_image(img)
		texture_cache[key] = tex
		return tex

func get_projectile_texture(proj_type: String) -> Texture2D:
	var key = "proj_" + proj_type
	if texture_cache.has(key):
		return texture_cache[key]
	
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	match proj_type:
		"arrow":
			_draw_rect(img, Rect2i(10, 4, 4, 16), Color(0.6, 0.4, 0.2)) # Shaft
			_draw_rect(img, Rect2i(9, 2, 6, 4), Color(0.85, 0.88, 0.92)) # Tip
			_draw_rect(img, Rect2i(8, 16, 8, 5), Color(0.9, 0.2, 0.3)) # Fletching
		"cannonball":
			_draw_filled_circle(img, Vector2i(12, 12), 8, Color(0.25, 0.27, 0.3))
			_draw_filled_circle(img, Vector2i(10, 10), 3, Color(0.5, 0.52, 0.55))
		"musket_bullet":
			_draw_filled_circle(img, Vector2i(12, 12), 5, Color(0.95, 0.85, 0.3))
			_draw_filled_circle(img, Vector2i(12, 12), 3, Color(1, 1, 0.8))
		"fireball":
			_draw_filled_circle(img, Vector2i(12, 12), 10, Color(1, 0.4, 0.05))
			_draw_filled_circle(img, Vector2i(12, 12), 7, Color(1, 0.8, 0.1))
			_draw_filled_circle(img, Vector2i(12, 12), 4, Color(1, 1, 0.8))
		"dark_orb":
			_draw_filled_circle(img, Vector2i(12, 12), 7, Color(0.35, 0.1, 0.5))
			_draw_filled_circle(img, Vector2i(12, 12), 4, Color(0.7, 0.25, 0.9))
		_:
			_draw_filled_circle(img, Vector2i(12, 12), 6, Color(1, 1, 1))

	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func get_card_icon(card_id: String) -> Texture2D:
	var key = "card_icon_" + card_id
	if texture_cache.has(key):
		return texture_cache[key]
	
	var img = Image.create(110, 140, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var card_data = CardDatabase.get_card(card_id)
	var bg_color = Color(0.2, 0.25, 0.35)
	if card_data.has("color"):
		bg_color = card_data["color"] * 0.45 + Color(0.1, 0.1, 0.15)
	
	# Rounded outer border (Golden/Silver)
	_draw_rect(img, Rect2i(2, 2, 106, 136), Color(0.85, 0.75, 0.35))
	_draw_rect(img, Rect2i(6, 6, 98, 128), Color(0.12, 0.14, 0.18))
	# Inner illustration background
	_draw_rect(img, Rect2i(10, 10, 90, 96), bg_color)
	
	# Mini illustration icon in center
	var is_spell = card_data.get("is_spell", false)
	if not is_spell:
		var unit_tex = get_unit_texture(card_id, 1)
		if unit_tex != null:
			var uimg = unit_tex.get_image()
			img.blend_rect(uimg, Rect2i(0, 0, 64, 64), Vector2i(23, 26))
	elif card_id == "fireball":
		_draw_filled_circle(img, Vector2i(55, 58), 26, Color(1, 0.4, 0.1))
		_draw_filled_circle(img, Vector2i(55, 58), 18, Color(1, 0.8, 0.2))
		_draw_filled_circle(img, Vector2i(55, 58), 10, Color(1, 1, 0.9))
	elif card_id == "arrows":
		for i in range(4):
			var ax = 30 + i * 16
			var ay = 35 + (i % 2) * 15
			_draw_rect(img, Rect2i(ax, ay, 4, 28), Color(0.8, 0.6, 0.2))
			_draw_rect(img, Rect2i(ax - 2, ay, 8, 6), Color(0.9, 0.95, 1))

	# Bottom Title Banner
	_draw_rect(img, Rect2i(8, 108, 94, 24), Color(0.18, 0.2, 0.25))
	_draw_rect(img, Rect2i(10, 110, 90, 20), Color(0.28, 0.3, 0.38))
	
	# Elixir Bubble on Top Left
	_draw_filled_circle(img, Vector2i(16, 16), 14, Color(0.9, 0.15, 0.7))
	_draw_filled_circle(img, Vector2i(16, 16), 11, Color(0.98, 0.3, 0.85))
	_draw_filled_circle(img, Vector2i(13, 13), 4, Color(1, 1, 1, 0.8))

	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func get_crown_texture(is_blue: bool = true) -> Texture2D:
	var key = "crown_" + str(is_blue)
	if texture_cache.has(key):
		return texture_cache[key]
	var img = Image.create(36, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col = Color(0.95, 0.8, 0.1)
	_draw_rect(img, Rect2i(6, 18, 24, 12), col)
	_draw_rect(img, Rect2i(6, 10, 6, 10), col)
	_draw_rect(img, Rect2i(15, 6, 6, 14), col)
	_draw_rect(img, Rect2i(24, 10, 6, 10), col)
	_draw_filled_circle(img, Vector2i(18, 24), 4, Color(0.2, 0.6, 0.95) if is_blue else Color(0.95, 0.2, 0.3))
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

func get_elixir_drop_texture() -> Texture2D:
	var key = "elixir_drop"
	if texture_cache.has(key):
		return texture_cache[key]
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_filled_circle(img, Vector2i(16, 18), 12, Color(0.85, 0.1, 0.65))
	_draw_filled_circle(img, Vector2i(16, 18), 9, Color(0.95, 0.3, 0.8))
	_draw_rect(img, Rect2i(14, 4, 4, 10), Color(0.95, 0.3, 0.8))
	_draw_filled_circle(img, Vector2i(12, 14), 3, Color(1, 1, 1, 0.7))
	var tex = ImageTexture.create_from_image(img)
	texture_cache[key] = tex
	return tex

# --- DRAWING PRIMITIVES ---

func _draw_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(max(0, rect.position.y), min(img.get_height(), rect.position.y + rect.size.y)):
		for x in range(max(0, rect.position.x), min(img.get_width(), rect.position.x + rect.size.x)):
			img.set_pixel(x, y, color)

func _draw_filled_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2 = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			var dx = x - center.x
			var dy = y - center.y
			if dx * dx + dy * dy <= r2:
				img.set_pixel(x, y, color)

func _draw_arc(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	var r2_inner = (radius - 2) * (radius - 2)
	var r2_outer = radius * radius
	for y in range(max(0, center.y - radius), min(img.get_height(), center.y + radius + 1)):
		for x in range(max(0, center.x - radius), min(img.get_width(), center.x + radius + 1)):
			var dx = x - center.x
			var dy = y - center.y
			var d2 = dx * dx + dy * dy
			if d2 <= r2_outer and d2 >= r2_inner and dx > 0:
				img.set_pixel(x, y, color)
