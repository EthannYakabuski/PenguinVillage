extends Node2D
@export var penguin_scene: PackedScene

var penguins = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	determinePenguins()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	determinePenguinIntelligence()

func determinePenguins() -> void: 
	print("loading penguins")
	var penguin: Penguin = penguin_scene.instantiate()
	penguin.setLocation(300,1300)
	penguin.setGoal(350, 1400)
	add_child(penguin)
	penguins.push_back(penguin)
	
func determinePenguinIntelligence() -> void: 
	#print("determining penguin intelligence")
	for p in penguins:
		if p.hasGoal():  
			p.moveToGoal()
	

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("location clicked")
		for p in penguins: 
			if p.selected: 
				print("controlling penguin")
				p.setGoal(event.position.x, event.position.y)
