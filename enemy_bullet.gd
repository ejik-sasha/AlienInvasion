extends Area2D
@export var speed = 1000

func start(_pos, _dir):
	position = _pos
	rotation = _dir.angle()
	
func _process(delta):
	position += transform.x * speed * delta

func _on_body_entered(body) -> void:
	if body.is_in_group("Players"):
		body.take_hit()
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	queue_free()
