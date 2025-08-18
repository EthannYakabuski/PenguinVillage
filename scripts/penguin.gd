extends Area2D

class_name Penguin

@export var penguin_frames: SpriteFrames = preload("res://animations/penguin_frames.tres")
#signal penguin_selected(state)

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
var health = 100
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
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

##SETTERS##
func setGoal(x, y) -> void:
	print("setting goal -> x: " + str(x) + " y: " + str(y)) 
	goal = Vector2(x, y)
	hasAGoal = true
	
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

func setCollisionGons(type) -> void: 
	if type == "Walk": 
		$PenguinCollision.set_deferred("polygon", walkOrIdlePolygons)
	elif type == "Swim": 
		$PenguinCollision.set_deferred("polygon", $PenguinCollisionSwimming.polygon)
		
func setSpeed(s) -> void: 
	speed = s
	
func setLocation(x, y) -> void: 
	position = Vector2(x, y)
	
func setCurrentArea(a) -> void: 
	current_area = a

##GETTERS##
func hasGoal() -> bool: 
	return hasAGoal
	
##INTERACTIONS##
func _on_input_event(_viewport, event, _shape_idx): 
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("Penguin Clicked")
		selected = true
		$PenguinSprite.modulate = Color(1, 1, 0, 1) # Yellow
		get_parent().onPenguinSelected(true)
		#stops background from also receiving the event
		get_viewport().set_input_as_handled()
		
##UTILITY##
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

func _on_penguin_sprite_animation_changed() -> void:
	if (current_state == "Swim"): 
		speed = 2
	elif (current_state == "Jump" or current_state == "Dive"): 
		speed = 3
	else: 
		speed = 1.25
