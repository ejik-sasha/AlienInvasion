extends Node
@export var rock_scene : PackedScene
@export var enemy_scene : PackedScene
var screensize = Vector2.ZERO
var level = 0
var score = 0
var playing = false

func _ready():
	screensize = get_viewport().get_visible_rect().size
	var player = $Player
	player.coins_changed.connect(_on_coins_changed)
	$HUD/VBoxContainer/ShopButton.pressed.connect(_on_shop_button_pressed)
	$SkinShop/CloseButton.pressed.connect(_on_close_shop)

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		$RockPath/RockSpawn.progress = randi()
		pos = $RockPath/RockSpawn.position
	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0,TAU)) * randf_range(50, 125)
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded)

func _on_rock_exploded(size, radius, pos, vel):
	score += 10 * size
	$HUD.update_score(score)
	if size <= 4:
		return
	for offset in [-1, 1]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos,newvel)

func new_game():
	get_tree().call_group("Enemies", "queue_free")
	get_tree().call_group("Rocks", "queue_free")
	level = 0
	score = 0
	$HUD.update_score(score)
	$HUD.show_message("Get Ready!")
	$Player.reset()
	await $HUD/Timer.timeout
	playing = true
	$Mobile_Joystick.visible = true
	
func new_level():
	level += 1
	$HUD.show_message("Level %s" % level)
	for i in level:
		spawn_rock(6)
	$EnemyTimer.start(randf_range(5, 10))

func _process(delta):
	if not playing:
		return
	if get_tree().get_nodes_in_group("Rocks").size() == 0:
		new_level()

func game_over():
	playing = false
	$HUD.game_over()
	$Mobile_Joystick.visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()
	


func _on_enemy_timer_timeout() -> void:
	var e = enemy_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20,40))


func _on_coins_changed(value):
	$HUD/CoinLabel.text = "Coins: %d" % value

func _on_shop_button_pressed():
	$SkinShop.visible = true

func _on_close_shop():
	$SkinShop.visible = false
