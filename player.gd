extends RigidBody2D
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT
@export var engine_power = 500
@export var spin_power = 8000
var thrust = Vector2.ZERO
var rotation_dir = 0
var screensize = Vector2.ZERO
@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
var can_shoot = true
signal lives_changed
signal dead
var reset_pos = false
var lives = 0: set = set_lives
var joystick_vector = Vector2.ZERO

func _ready():
	$Sprite2D.hide()
	screensize = get_viewport_rect().size
	change_state(INIT)
	$GunCooldown.wait_time = fire_rate
	var joystick = get_tree().get_root().get_node("Main/Mobile_Joystick")
	joystick.connect("use_move_vector", Callable(self, "_on_joystick_input"))
	var fire_button = get_tree().get_root().get_node("Main/Mobile_Joystick/FireButton")
	fire_button.pressed.connect(self._on_fire_button_pressed)


func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$Sprite2D2.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
			$Sprite2D2.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$Sprite2D2.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.set_deferred("disabled", true)
			$Sprite2D.hide()
			$Sprite2D2.hide()
			linear_velocity = Vector2.ZERO
			dead.emit()
	state = new_state
	
func _process(delta):
	get_input()
	
func get_input():
	thrust = Vector2.ZERO
	if state in [DEAD, INIT]:
		return
	if joystick_vector.length() > 0:
		var desired_angle = joystick_vector.angle()
		var angle_diff = wrapf(desired_angle - rotation, -PI, PI)
		rotation_dir = sign(angle_diff)
		thrust = transform.x * engine_power
	else:
		if Input.is_action_pressed("thrust"):
			thrust = transform.x * engine_power
		rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()




func _physics_process(delta):
	constant_force = thrust
	constant_torque = rotation_dir * spin_power
	
func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false

func shoot():
	if state == INVULNERABLE:
		return
	can_shoot = false
	$GunCooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start($Muzzle.global_transform)


func _on_gun_cooldown_timeout():
	can_shoot = true

func set_lives(value):
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(DEAD)
	else:
		change_state(INVULNERABLE)

func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(ALIVE)


func _on_invulnerability_timer_timeout() -> void:
	change_state(ALIVE)

func _on_body_entered(body):
	if body.is_in_group("Rocks"):
		body.explode()
		lives -= 1
		explode()

func explode():
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")
	await $Explosion/AnimationPlayer.animation_finished
	$Explosion.hide()

func _on_joystick_input(vector):
	joystick_vector = vector

func _on_fire_button_pressed():
	if can_shoot:
		shoot()
