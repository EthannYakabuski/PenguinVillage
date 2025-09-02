extends Area2D

class_name Penguin

@export var penguin_frames: SpriteFrames = preload("res://animations/penguin_frames.tres")
signal penguinNeedsGoal(penguin)

#internals
var screen_size

#mechanics
var current_state: String
var current_area: String
var goal: Vector2
var hasAGoal: bool = false
var speed = 0.75
var selected: bool = false

#vitals
var food = 100
var health
var sick = false

#collision polygons
var walkOrIdlePolygons

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	walkOrIdlePolygons = $PenguinCollision.polygon
	setState("Idle")
	$PenguinSprite.play()
	$PenguinCollision.set_deferred("input_pickable", true)
	screen_size = get_viewport_rect().size
	$HealthIndicator.value = health
	$HealthIndicator.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

##SETTERS##
func setGoal(x, y) -> void:
	print("setting goal -> x: " + str(x) + " y: " + str(y)) 
	goal = Vector2(x, y)
	hasAGoal = true
	useEnergy(1)
	
func setState(state: String) -> void: 
	if state != current_state: 
		print("setting penguin state to " + state)
		print("current area : " + current_area)
		current_state = state
		$PenguinSprite.animation = state
	
func setSelected(state: bool) -> void: 
	selected = state
	if !state: 
		$PenguinSprite.modulate = Color(1,1,1,1) #Resets to original
		$HealthIndicator.visible = false
		
func setHealthIndicatorVisibility(state: bool) -> void: 
	$HealthIndicator.visible = state
	
func setCollisionGons(type) -> void: 
	if type == "Walk": 
		$PenguinCollision.set_deferred("polygon", walkOrIdlePolygons)
	elif type == "Swim": 
		$PenguinCollision.set_deferred("polygon", $PenguinCollisionSwimming.polygon)
		
func setSpeed(s) -> void: 
	speed = s
	
func setLocation(x, y) -> void: 
	global_position = Vector2(x, y)
	
func setCurrentArea(a) -> void: 
	if current_area != a: 
		current_area = a

func startTime() -> void: 
	$SlidingGoalTimer.start()
	
func stopTime() -> void: 
	$SlidingGoalTimer.stop()
	
func setHealth(h) -> void: 
	print("setting penguin health to " + str(h))
	health = h
	$HealthIndicator.value = h
	
func addHealth(h) -> void: 
	health = health + h
	if health > 100: 
		health = 100
	$HealthIndicator.value = health
	
func setSick(s) -> void:
	print("setting penguin sick to " + str(s)) 
	sick = s
	
func setFood(f) -> void: 
	print("setting penguin food to " + str(f))
	food = f
	
func clearGoal() -> void: 
	hasAGoal = false

##GETTERS##
func hasGoal() -> bool: 
	return hasAGoal

func getState() -> String:
	return current_state
	
##INTERACTIONS##
func _on_input_event(_viewport, event, _shape_idx): 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("Penguin Clicked")
		selected = true
		$HealthIndicator.visible = true
		$PenguinSprite.modulate = Color(1, 1, 0, 1) # Yellow
		get_parent().onPenguinSelected(true)
		#stops background from also receiving the event
		get_viewport().set_input_as_handled()
		
##UTILITY##
func useEnergy(amount) -> void: 
	health = health - amount
	if food < 0: 
		sick = true
		food = 0
	$HealthIndicator.value = health

func moveToGoal() -> void: 
	var direction = (goal - global_position).normalized()
	if global_position.distance_to(goal) > 1:
		$PenguinSprite.flip_h = direction.x < 0
		global_position += direction * speed
		#position = position.clamp(Vector2.ZERO, screen_size)
	else: 
		if current_area == "Water": 
			setState("Swim")
		else:
			setState("Idle")
		

func _on_penguin_sprite_animation_looped() -> void:
	if current_state == "Dive" && current_area == "Water": 
		setState("Swim")
	elif current_state == "Jump" && current_area == "Ice" && hasAGoal: 
		setState("Walk")
	elif current_state == "Jump" && current_area == "Ice":
		setState("Idle")
	elif current_state == "Slide": 
		setState("StillSliding")

func _on_penguin_sprite_animation_changed() -> void:
	if (current_state == "Swim"): 
		speed = 2
	elif (current_state == "Jump" or current_state == "Dive"): 
		speed = 3
	elif (current_state == "Slide"): 
		speed = 2.25
	else: 
		speed = 1.25

func _on_sliding_goal_timer_timeout() -> void:
	$SlidingGoalTimer.wait_time = randf_range(1,2)
	penguinNeedsGoal.emit(self)
	#emit_signal("penguinNeedsGoal", self)
