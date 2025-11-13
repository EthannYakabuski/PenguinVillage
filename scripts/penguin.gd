extends Area2D

class_name Penguin

@export var penguin_frames: SpriteFrames = preload("res://animations/penguin_frames.tres")
signal penguinNeedsGoal(penguin)

#internals
var screen_size
var addedToScene = false

#mechanics
var current_state: String
var last_state: String
var current_area: String
var goal: Vector2
var hasAGoal: bool = false
var speed = 0.75
var selected: bool = false

#vitals
var food = 100
var steps = 0
var health
var sick = false

#collision polygons
var walkOrIdlePolygons

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	walkOrIdlePolygons = $PenguinCollision.polygon
	setState("Idle")
	addedToScene = true
	$PenguinSprite.play()
	$PenguinCollision.set_deferred("input_pickable", true)
	screen_size = get_viewport_rect().size
	$HealthIndicator.value = food
	$HealthIndicator.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

##SETTERS##
func setGoal(x, y) -> void:
	print("setting goal -> x: " + str(x) + " y: " + str(y)) 
	goal = Vector2(x, y)
	hasAGoal = true
	useEnergy(3)
	
func setState(state: String) -> void: 
	if state != current_state: 
		print("setting penguin state to " + state)
		print("current area : " + current_area)
		last_state = current_state
		current_state = state
		$PenguinSprite.animation = state
	
func setSelected(state: bool) -> void: 
	selected = state
	if !state: 
		if !sick:
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
	$HealthIndicator.value = food
	
func addHealth(h) -> void: 
	health = health + h
	if health > 100: 
		health = 100
	#$HealthIndicator.value = health
	
func addFood(f) -> void: 
	food = food + f
	if food > 100: 
		food = 100
	$HealthIndicator.value = food
	
func setSick(s) -> void:
	print("setting penguin sick to " + str(s))
	#if the penguin is currently sick, and is being cured, restore its speed value 
	if sick && !s: 
		speed = speed/0.5
	if s: 
		$PenguinSprite.modulate = Color(0.5,1.0,0.5,1.0) 
		$HealthIndicator.tint_progress = Color(0.5,1.0,0.5,1.0)
		if addedToScene: 
			$SickTimer.start()
	else: 
		$PenguinSprite.modulate = Color(1.0,1.0,1.0,1.0) 
		$HealthIndicator.tint_progress = Color(0.8,0.15,0.31,1.0)
	sick = s
	
func setFood(f) -> void: 
	print("setting penguin food to " + str(f))
	food = f
	$HealthIndicator.value = food
	
func clearGoal() -> void: 
	hasAGoal = false

##GETTERS##
func hasGoal() -> bool: 
	return hasAGoal

func getState() -> String:
	return current_state
	
func getSick() -> bool: 
	return sick
	
##INTERACTIONS##
func _on_input_event(_viewport, event, _shape_idx): 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("Penguin Clicked")
		if current_state == "Dead":
			print("calling get parent penguin died") 
			get_parent().onPenguinDied()
		selected = true
		$HealthIndicator.visible = true
		if !sick:
			$PenguinSprite.modulate = Color(1, 1, 0, 1) # Yellow
		get_parent().onPenguinSelected(true)
		#stops background from also receiving the event
		get_viewport().set_input_as_handled()
		
##UTILITY##
func useEnergy(amount) -> void: 
	food = food - amount
	if food <= 0: 
		setSick(true)
		food = 0
	$HealthIndicator.value = food

func moveToGoal() -> void:
	var direction = (goal - global_position).normalized()
	if global_position.distance_to(goal) > 1:
		$PenguinSprite.flip_h = direction.x < 0
		global_position += direction * speed
		steps = steps + 1
		#print(steps)
		if steps >= 250: 
			useEnergy(1)
			steps = 0
		if current_state == "Walk" and not $FootStepSound.playing: 
			$FootStepSound.play()
		#position = position.clamp(Vector2.ZERO, screen_size)
	else: 
		if current_area == "Water": 
			setState("Swim")
		else:
			$FootStepSound.stop()
			setState("Idle")
		clearGoal()
		

func _on_penguin_sprite_animation_looped() -> void:
	if current_state == "Dive" && current_area == "Water": 
		setState("Swim")
	elif current_state == "Jump" && current_area == "Ice" && hasAGoal: 
		setState("Walk")
	elif current_state == "Jump" && current_area == "Ice":
		setState("Idle")
	elif current_state == "Slide": 
		setState("StillSliding")
	elif current_state == "Hurt": 
		setState(last_state)
	elif current_state == "Die": 
		setState("Dead")
		
func _on_penguin_sprite_animation_changed() -> void:
	if (current_state == "Swim"): 
		speed = 2
	elif (current_state == "Jump" or current_state == "Dive"): 
		speed = 3
	elif (current_state == "Slide" || current_state == "StillSliding"): 
		speed = 2.25
	else: 
		speed = 1.25
	if sick: 
		speed = speed * 0.5

func _on_sliding_goal_timer_timeout() -> void:
	$SlidingGoalTimer.wait_time = randf_range(1,2)
	penguinNeedsGoal.emit(self)
	#emit_signal("penguinNeedsGoal", self)


func _on_sick_timer_timeout() -> void:
	if sick and current_state != "Dead":
		var randomChanceOfDeath = randf_range(0,100)
		if (randomChanceOfDeath > 97): 
			setState("Die")
			hasAGoal = false
		else:  
			setState("Hurt")
			$SickTimer.wait_time = randf_range(3,5)
		useEnergy(1)
		
