extends Area2D

class_name Fish

@export var penguin_frames: SpriteFrames = preload("res://animations/fish_frames.tres")

#internals
var sprite: AnimatedSprite2D

#mechanics
var current_state: String
var goal: Vector2
var hasAGoal: bool = false
var speed = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite = $FishSprite
	setState("Idle")
	sprite.play()
	$FishCollision.set_deferred("input_pickable", true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

##SETTERS##
func setGoal(x, y) -> void: 
	goal = Vector2(x, y)
	hasAGoal = true
	
func setState(state: String) -> void: 
	current_state = state
	sprite.animation = state
	
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
		print("Fish Clicked")
		
##UTILITY##
func moveToGoal() -> void: 
	var direction = (goal - position).normalized()
	if position.distance_to(goal) > 5:
		$FishSprite.flip_h = direction.x < 0
		#setState("Walk")
		position += direction * speed
	else: 
		setState("Idle")
