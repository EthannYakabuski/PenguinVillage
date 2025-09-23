extends TextureProgressBar


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("heart added to scene")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setValue(val) -> void: 
	value = val
