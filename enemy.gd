extends Area2D
@export var bullet_scene: PackedScene
@export var coin_scene: PackedScene
@export var speed = 150
@export var rotation_speed = 120
@export var health = 3
@export var bullet_spread = 0.2
var follow = PathFollow2D.new()
var target = null
var player = null

func _ready():
	$AnimationPlayer.play("idle")
	var path = $EnemyPaths.get_children()[randi_range(0, 2)]
	path.add_child(follow)
	follow.loop = false
	player = get_tree().get_root().get_node("Main/Player")

func _physics_process(delta):
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position
	if follow.progress_ratio >= 1:
		queue_free()

func _on_gun_cooldown_timeout() -> void:
	shoot_pulse(3, 0.15)
	#shoot()

func shoot():
	var dir = global_position.direction_to(target.global_position)
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(global_position, dir)

func shoot_pulse(n, delay):
	for i in n:
		shoot()
		await get_tree().create_timer(delay).timeout

func take_damage(amount):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()
		

func explode():
	if coin_scene:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		coin.picked_up.connect(player.collect_coin)
	coin_scene = null
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("Rocks"):
		return
	if body.is_in_group("Players"):
		body.take_hit()
		body.take_hit()
		body.take_hit()
		body.take_hit()
		body.take_hit()
		explode()
