extends Area2D

class_name Fish

@export var penguin_frames: SpriteFrames = preload("res://animations/fish_frames.tres")
signal fish_collected(fish)
signal fish_needs_target(fish)

#internals
var sprite: AnimatedSprite2D
var id

#mechanics
var current_state: String
var goal: Vector2
var hasAGoal: bool = false
var speed = 0.5

#predator/prey mechanics
var currentState = "safe"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite = $FishSprite
	setState("Idle")
	sprite.play()
	$FishCollision.set_deferred("input_pickable", true)
	$IdleChange.start()
	$DangerCheck.start()
	
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

##UTILITY##
func moveToGoal() -> void: 
	var direction = (goal - global_position).normalized()
	if global_position.distance_to(goal) > 1:
		$FishSprite.flip_h = direction.x < 0
		#setState("Walk")
		global_position += direction * speed
	else: 
		setState("Idle")

func _on_area_entered(area: Area2D) -> void:
	if area is Penguin: 
		print("a penguin captured a fish")
		queue_free()
		emit_signal("fish_collected", self)

func _on_idle_change_timeout() -> void:
	if currentState == "safe":
		setSpeed(0.5)
		emit_signal("fish_needs_target", self)
		
func _on_danger_check_timeout() -> void:
	if currentState == "danger": 
		print("fish in danger")
		setSpeed(2)
	
