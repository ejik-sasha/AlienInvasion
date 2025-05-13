extends Area2D

signal picked_up

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Players"): 
		picked_up.emit()
		queue_free()
