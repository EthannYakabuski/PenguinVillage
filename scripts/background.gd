extends Node2D
@export var penguin_scene: PackedScene
@export var fish_scene: PackedScene
@export var food_scene: PackedScene
@onready var fishTimer: Timer = $FishSpawnTimer

var penguins = []
var fishes = []
#var foodBowls = []
var foodBowl: Food

var penguinIsSelected = false

#google play integration
@onready var googleSignInClient: PlayGamesSignInClient = $Android_SignIn
@onready var googleSnapshotClient: PlayGamesSnapshotsClient = $Android_SavedGames

func _enter_tree() -> void: 
	GodotPlayGameServices.initialize()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	androidAuthentication()
	determinePenguins()
	determineFish()
	determineFood()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	determinePenguinIntelligence()
	determineFishIntelligence()

##SOCIAL CONNECTIONS##
func androidAuthentication() -> void: 
	if not GodotPlayGameServices.android_plugin: 
		printerr("Plugin not found")
	else: 
		print("Plugin found")
		googleSignInClient.is_authenticated()

func _on_user_authenticated(is_authenticated: bool) -> void:
	print("Hi from Godot! User is authenticated? %s" % is_authenticated)
	#hideOrShowAuthenticatedButtons(is_authenticated)
	#play_games_sign_in_client.is_authenticated()

##PENGUINS##
func determinePenguins() -> void: 
	print("loading penguins")
	var penguin: Penguin = penguin_scene.instantiate()
	penguin.setLocation(300,1400)
	add_child(penguin)
	penguins.push_back(penguin)
	
func determinePenguinIntelligence() -> void: 
	#print("determining penguin intelligence")
	for p in penguins:
		if p.hasGoal():  
			p.moveToGoal()
			
##FISH##
func determineFish() -> void: 
	print("loading fish")
	var fish: Fish = fish_scene.instantiate()
	fish.setLocation(500, 1700)
	fish.fish_collected.connect(onFishCollected)
	add_child(fish)
	fishes.push_back(fish)
	
func determineFishIntelligence() -> void: 
	for f in fishes: 
		if f.hasGoal(): 
			f.moveToGoal()
			
##FOOD##
func determineFood() -> void: 
	print("loading food bowls")
	var food: Food = food_scene.instantiate()
	food.setLocation(550, 1350)
	add_child(food)
	foodBowl = food
	foodBowl.addFood(50)
	#foodBowls.push_back(food)
			
##CUSTOM SIGNAL LISTENERS##
func onFishCollected(fish) -> void: 
	print("fish collected")
	if fish in fishes: 
		fishes.erase(fish)
		foodBowl.addFood(20)
	fish.queue_free()

func onPenguinSelected(state) -> void: 
	penguinIsSelected = state
	print("penguin selected")

##EVENT LISTENERS##
func _on_ice_berg_area_area_entered(_area: Area2D) -> void:
	print("something entered ice berg area")
	
func _on_water_area_area_entered(area: Area2D) -> void:
	print("something entered water area")
	if area is Penguin:
		print("a penguin entered the water area")
		area.setState("Dive")
	
##GUI###
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("location clicked")
		for p in penguins: 
			if p.selected: 
				print("controlling penguin")
				p.setGoal(event.position.x, event.position.y)
				p.setSelected(false)
				p.setState("Walk")
