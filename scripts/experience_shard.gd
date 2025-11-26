extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	position.y = position.y - 2
	modulate.a = modulate.a - 0.01
	scale = scale + Vector2.ONE * 0.001

func _on_visible_timer_timeout() -> void:
	visible = false
	queue_free()
	
func setLabel(amount) -> void: 
	$ExperienceLabel.text = str(amount)
	
func startTimer() -> void: 
	$VisibleTimer.start()
