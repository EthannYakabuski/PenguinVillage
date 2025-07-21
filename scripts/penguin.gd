extends Area2D

class_name Penguin

@export var penguin_frames: SpriteFrames = preload("res://animations/penguin_frames.tres")
signal penguin_selected(state)

#internals

#mechanics
var current_state: String
var goal: Vector2
var hasAGoal: bool = false
var speed = 0.75
var selected: bool = false

#vitals
var food = 100
var health = 100
var sick = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setState("Idle")
	$PenguinSprite.play()
	$PenguinCollision.set_deferred("input_pickable", true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

##SETTERS##
func setGoal(x, y) -> void: 
	goal = Vector2(x, y)
	hasAGoal = true
	
func setState(state: String) -> void: 
	current_state = state
	$PenguinSprite.animation = state
	#$PenguinSprite.play()
	
func setSelected(state: bool) -> void: 
	selected = state
	if !state: 
		$PenguinSprite.modulate = Color(1,1,1,1) #Resets to original
	
func setSpeed(s) -> void: 
	speed = s
	
func setLocation(x, y) -> void: 
	position = Vector2(x, y)

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
		
##UTILITY##
func moveToGoal() -> void: 
	var direction = (goal - position).normalized()
	if position.distance_to(goal) > 5:
		$PenguinSprite.flip_h = direction.x < 0
		#setState("Walk")
		position += direction * speed
	else: 
		setState("Idle")


func _on_penguin_sprite_animation_finished() -> void:
	if current_state == "Dive": 
		setState("Swim")
		
