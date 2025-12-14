extends Area2D

class_name Food

var foodLevel = 0
var selected = false

const LONG_PRESS_TIME := 0.75 # seconds

var pressing := false
var pressStartTime := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if pressing: 
		var heldTime = Time.get_ticks_msec() / 1000.0 - pressStartTime
		if heldTime > LONG_PRESS_TIME: 
			get_parent().foodBowlHeld(self)
	
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
	
func _on_input_event(_viewport, event, _shape_idx): 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("Food clicked")
		pressing = true
		pressStartTime = Time.get_ticks_msec() / 1000.0
		get_viewport().set_input_as_handled()
	else:
		if not pressing: 
			return
		pressing = false

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
		
