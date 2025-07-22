extends Area2D

class_name Food

var foodLevel = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
##SETTERS##
func setLocation(x, y) -> void: 
	position = Vector2(x, y)
	
func addFood(amount) -> void: 
	foodLevel = foodLevel + amount
	if(foodLevel >= 60): 
		$FoodSprite.animation = "Full"
	elif (foodLevel < 60 and foodLevel > 10): 
		$FoodSprite.animation = "Medium"
	else: 
		$FoodSprite.animation = "Empty"
	
##GETTERS##
func getFoodLevel() -> int: 
	return foodLevel
