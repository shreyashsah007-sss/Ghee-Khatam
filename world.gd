extends Node2D

@onready var player = $Player
@onready var bouncy_tpl = $BouncyTemplate
@onready var deadly_tpl = $DeadlyTemplate
@onready var score_label = $ScoreLabel
@onready var game_over_label = $GameOverLabel
@onready var fahh_sound = $FahhSound

const GROUND_Y = 535.0
const GRAVITY = 1900.0
const JUMP_FORCE = -720.0
const SUPER_BOUNCE_FORCE = -1000.0

var vel_y = 0.0
var is_grounded = true
var is_dead = false
var score = 0.0
var game_speed = 420.0
var spawn_timer = 1.2
var active_hazards = []

func _ready():
	if has_node("BgMusic") and $BgMusic.stream != null:
		$BgMusic.play()

	for bg_name in ["Background", "Background2"]:
		if has_node(bg_name):
			var bg = get_node(bg_name)
			if bg is TextureRect:
				bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				bg.stretch_mode = TextureRect.STRETCH_SCALE
				bg.size = Vector2(1152, 648)
	if has_node("Background"):
		$Background.position = Vector2(0, 0)
	if has_node("Background2"):
		$Background2.position = Vector2(1152, 0)

	player.position = Vector2(180, GROUND_Y)
	player.area_entered.connect(_on_player_hit)
	
	for tpl in [bouncy_tpl, deadly_tpl]:
		tpl.visible = false
		tpl.position = Vector2(-500, -500)
	
	bouncy_tpl.modulate = Color.ORANGE
	deadly_tpl.modulate = Color.RED
	
	game_over_label.visible = false
	game_over_label.text = "Ghee Khatam!\nPress SPACE to Bounce Back"

func _process(delta):
	if is_dead:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return

	score += delta * 10.0
	game_speed += delta * 8.0
	score_label.text = "Score: " + str(int(score))

	for bg_name in ["Background", "Background2"]:
		if has_node(bg_name):
			var bg = get_node(bg_name)
			bg.position.x -= (game_speed * 0.5) * delta
			if bg.position.x <= -1152:
				bg.position.x += 2304

	if Input.is_action_just_pressed("ui_accept") and is_grounded:
		vel_y = JUMP_FORCE
		is_grounded = false

	vel_y += GRAVITY * delta
	player.position.y += vel_y * delta

	if player.position.y >= GROUND_Y:
		player.position.y = GROUND_Y
		vel_y = 0.0
		is_grounded = true

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_hazard()
		spawn_timer = randf_range(0.9, 1.7)

	for i in range(active_hazards.size() - 1, -1, -1):
		var h = active_hazards[i]
		h.position.x -= game_speed * delta
		if h.position.x < -100:
			active_hazards.remove_at(i)
			h.queue_free()

func spawn_hazard():
	var clone
	if randi() % 2 == 0:
		clone = bouncy_tpl.duplicate()
		clone.set_meta("type", "bouncy")
		var y_pos = GROUND_Y if randf() > 0.5 else GROUND_Y - 90.0
		clone.position = Vector2(1250, y_pos)
	else:
		clone = deadly_tpl.duplicate()
		clone.set_meta("type", "deadly")
		clone.position = Vector2(1250, GROUND_Y)
		
	clone.visible = true
	add_child(clone)
	active_hazards.append(clone)

func _on_player_hit(area):
	if is_dead or not area.has_meta("type"):
		return
		
	if area.get_meta("type") == "bouncy":
		vel_y = SUPER_BOUNCE_FORCE
		is_grounded = false
		score += 25
		area.visible = false
		if has_node("BounceSound") and $BounceSound.stream != null:
			$BounceSound.play()
	else:
		is_dead = true
		if has_node("BgMusic"):
			$BgMusic.stop()
		game_over_label.visible = true
		if fahh_sound.stream != null:
			fahh_sound.play()
