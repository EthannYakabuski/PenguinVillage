extends Sprite2D

signal prizeAccepted

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setDisplayedLevel(level, doubleLevel) -> void: 
	$LevelIndicator/LevelLabel.text = str(level)
	setDisplayedPrize(level, doubleLevel)

func _on_accept_prize_pressed() -> void:
	print("accepting level up prize")
	prizeAccepted.emit()
	queue_free()
	
func setDisplayedPrize(level, doubleLevel) -> void: 
	print("setting displayed prize")
