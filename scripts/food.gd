extends Area2D

class_name Food

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
##SETTERS##
func setLocation(x, y) -> void: 
	position = Vector2(x, y)
