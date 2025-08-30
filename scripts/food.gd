extends Area2D

class_name Food

var foodLevel = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
##SETTERS##
func setLocation(x, y) -> void: 
	position = Vector2(x, y)
	
func animateFood(): 
	if(foodLevel >= 85): 
		$FoodSprite.animation = "CompletelyFull"
	elif (foodLevel < 85 and foodLevel > 65): 
		$FoodSprite.animation = "Full"
	elif (foodLevel <= 65 and foodLevel > 40): 
		$FoodSprite.animation = "AlmostFull"
	elif (foodLevel <= 40 and foodLevel > 15): 
		$FoodSprite.animation = "Medium"
	elif (foodLevel <= 15 and foodLevel > 5): 
		$FoodSprite.animation = "AlmostEmpty"
	else: 
		$FoodSprite.animation = "Empty"

func useFood(amount) -> void: 
	if foodLevel > 0: 
		foodLevel = foodLevel - amount
		animateFood()
	
func addFood(amount) -> void: 
	foodLevel = foodLevel + amount
	if foodLevel > 100: 
		foodLevel = 100
	animateFood()
	
##GETTERS##
func getFoodLevel() -> int: 
	return foodLevel

##penguin comes to eat food
func _on_area_entered(area: Area2D) -> void:
	if area is Penguin: 
		print("a penguin came to eat")
		if foodLevel >= 5: 
			if area.food < 100: 
				area.setHealthIndicatorVisibility(true)
				#area.addHealth(10)
				area.setState("Eat")
				area.clearGoal()
		
