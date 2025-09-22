extends Control

signal penguinDropped
signal foodDropped
signal medicineDropped

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _can_drop_data(_at_position: Vector2, _data) -> bool: 
	return true

func _drop_data(at_position: Vector2, data) -> void: 
	print("there is data getting dropped")
	print(at_position)
	if data.controlItemType == "Penguin":
		print("a penguin has been dropped")
		penguinDropped.emit()
	elif data.controlItemType == "Food": 
		print("a food bag has been dropped")
		foodDropped.emit()
	elif data.controlItemType == "Medicine": 
		print("a medicine bag has been dropped")
		medicineDropped.emit()
