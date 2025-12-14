extends Control

class_name Food

var foodLevel = 0
var selected = false

const LONG_PRESS_TIME := 0.75 # seconds

var pressing := false
var pressStartTime := 0.0

var controlItemType = "FoodBowlDrag"

var completelyFull = preload("res://images/FoodBowl_full.png")
var full = preload("res://images/FoodBowl_full.png")
var almostFull = preload("res://images/FoodBowl_almostFull.png")
var medium = preload("res://images/FoodBowl_medium.png")
var almostEmpty = preload("res://images/FoodBowl_almostEmpty.png")
var empty = preload("res://images/FoodBowl_empty.png")


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
		$Food/FoodTexture.texture = completelyFull
		$Food/FoodSprite.animation = "CompletelyFull"
	elif (foodLevel < 85 and foodLevel > 65): 
		$Food/FoodSprite.animation = "Full"
		$Food/FoodTexture.texture = full
	elif (foodLevel <= 65 and foodLevel > 40): 
		$Food/FoodSprite.animation = "AlmostFull"
		$Food/FoodTexture.texture = almostFull
	elif (foodLevel <= 40 and foodLevel > 15): 
		$Food/FoodSprite.animation = "Medium"
		$Food/FoodTexture.texture = medium
	elif (foodLevel <= 15 and foodLevel > 5): 
		$Food/FoodSprite.animation = "AlmostEmpty"
		$Food/FoodTexture.texture = almostEmpty
	else: 
		$Food/FoodSprite.animation = "Empty"
		$Food/FoodTexture.texture = empty

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
		#get_viewport().set_input_as_handled()
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
				
func _get_drag_data(_Vector2):
	print("get drag data on a food bowl is being called")
	$Food/FoodTexture.visible = false
	get_parent().dragToggle()
	var preview = TextureRect.new()
	preview.texture = $Food/FoodTexture.texture
	preview.size = $Food/FoodTexture.size
	preview.scale.x = $Food/FoodTexture.scale.x
	preview.scale.y = $Food/FoodTexture.scale.y
	set_drag_preview(preview)
	return self
		
