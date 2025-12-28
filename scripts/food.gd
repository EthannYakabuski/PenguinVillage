extends Control

class_name Food

var foodLevel = 0
var selected = false
var dragging = false

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
			print("setting dragging to true in process()") 
			dragging = true
			get_parent().foodBowlHeld(self)
	else: 
		pass
		#pressing = false
		#dragging = false
	if dragging:
		#print("food bowl is getting dragged") 
		#global_position = get_viewport().get_mouse_position()
		#global_position = get_viewport().get_mouse_position()
		global_position = get_parent().getCamera().get_global_mouse_position()
		#if (get_parent().currentDragDelta > 0): 
			#global_position.x = global_position.x - get_parent().currentDragDelta
		#else:
			#global_position.x = global_position.x - get_parent().currentDragDelta
	
##SETTERS##
func setLocation(x, y) -> void: 
	position = Vector2(x, y)
	
func getLocation() -> Vector2: 
	return global_position
	
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
		print("setting pressing to true")
		pressing = true
		pressStartTime = Time.get_ticks_msec() / 1000.0
		#get_viewport().set_input_as_handled()
	else:
		if not pressing:
			#print("not pressing, return") 
			return
		print("setting pressing to false")
		pressing = false
	
	#essentially mouse up on drag
	if dragging and event is InputEventMouseButton and not event.pressed:
		print("mouse up in food bowl")
		print("setting dragging to false")
		dragging = false
		get_parent().setDragToggle(false)
		
func _notification(what: int) -> void: 
	if what == NOTIFICATION_DRAG_END: 
		print("mouse up in notification on food bowl")
		if not get_parent().isTutorialCompleted and int(get_parent().tutorialProgress) == int(9): 
			get_parent().updateTutorialProgress(10)
			get_parent().checkTutorialProgress()
		dragging = false
		get_parent().setDragToggle(false)
		get_parent().updatePenguinAndFoodSavedArray()

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
				
func _get_drag_data(atPos: Vector2) -> Control:
	print("get drag data on a food bowl is being called")
	#$Food/FoodTexture.visible = false
	print("setting dragging to true")
	dragging = true
	get_parent().dragToggle()
	var previewTex = TextureRect.new()
	previewTex.texture = $Food/FoodTexture.texture
	previewTex.size = $Food/FoodTexture.size
	previewTex.scale.x = $Food/FoodTexture.scale.x
	previewTex.scale.y = $Food/FoodTexture.scale.y
	#previewTex.position = get_parent().getCamera().get_local_mouse_position()
	#previewTex.position.x = get_parent().getCamera().get_global_mouse_position().x - get_parent().currentDragDelta
	
	var preview = Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#preview.position = get_parent().getCamera().get_global_mouse_position()
	preview.add_child(previewTex)
	#preview.visible = false
	#set_drag_preview(preview)
	#add_child(preview)
	return self
		
