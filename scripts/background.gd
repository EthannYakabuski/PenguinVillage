extends Node2D
@export var penguin_scene: PackedScene
@export var fish_scene: PackedScene
@export var food_scene: PackedScene
@onready var fishTimer: Timer = $FishSpawnTimer

#UI interactions

var penguins = []
var fishes = []
#var foodBowls = []
var foodBowl: Food

var penguinIsSelected = false

#google play integration
@onready var googleSignInClient: PlayGamesSignInClient = $Android_SignIn
@onready var googleSnapshotClient: PlayGamesSnapshotsClient = $Android_SavedGames
var currentData = ""

#admob integration
var _ad_view : AdView
var _rewarded_ad : RewardedAd
var _full_screen_content_callback : FullScreenContentCallback
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()

func _enter_tree() -> void: 
	GodotPlayGameServices.initialize()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	androidAuthentication()
	admobConfiguration()
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
	
func admobConfiguration() -> void: 
	var onInitializationCompleteListener = OnInitializationCompleteListener.new()
	onInitializationCompleteListener.on_initialization_complete = onAdInitializationComplete
	var request_configuration = RequestConfiguration.new()
	MobileAds.initialize(onInitializationCompleteListener)
	if MobileAds: 
		MobileAds.set_request_configuration(request_configuration)
		
#called after admob init is complete, loads a banner ad
func onAdInitializationComplete(status : InitializationStatus): 
	print("banner ad initialization complete")
	_create_ad_view()
	
#code to load banner ad
func _create_ad_view() -> void:
	#free memory
	if _ad_view:
		destroy_ad_view()

	var adListener = AdListener.new()
	adListener.on_ad_failed_to_load = func(load_ad_error : LoadAdError):
		pass 
	
	var unit_id = "ca-app-pub-3940256099942544/6300978111"

	_ad_view = AdView.new(unit_id, AdSize.BANNER, AdPosition.Values.TOP)
	var ad_request = AdRequest.new()
	_ad_view.load_ad(ad_request)
	_ad_view.show()
	
func destroy_ad_view():
	if _ad_view:  
		_ad_view.destroy()
		_ad_view = null

#code to launch a rewarded ad, triggered manually by player
func _on_ad_button_pressed() -> void:
	if _rewarded_ad: 
		_rewarded_ad.destroy()
		_rewarded_ad = null
		
	var unit_id = "ca-app-pub-3940256099942544/5224354917"
	
	var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
	
	rewarded_ad_load_callback.on_ad_failed_to_load = func(adError: LoadAdError) -> void: 
		print(adError.message)
	
	rewarded_ad_load_callback.on_ad_loaded = func(rewarded_ad: RewardedAd) -> void: 
		print("rewarded ad loaded")
		_rewarded_ad = rewarded_ad
		_rewarded_ad.full_screen_content_callback = _full_screen_content_callback
		_rewarded_ad.show(on_user_earned_reward_listener)
		
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), rewarded_ad_load_callback)
		

#called after user watches the manually launched rewarded ad
func on_user_earned_reward(rewarded_item : RewardedItem):
	print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	#once we are using an actual unit-id from admob, the rewarded_item.amount and rewarded_item.type values are set in the admob console
	
	#TODO - reward player with reward

##GOOGLE PLAY GAME SERVICES##
func _on_user_authenticated(is_authenticated: bool) -> void:
	print("Hi from Godot! User is authenticated? %s" % is_authenticated)
	if is_authenticated: 
		$Android_SavedGames.load_game("PlayerData", true)
	$Android_SavedGames.game_loaded.connect(
		func(snapshot: PlayGamesSnapshot): 
			if !snapshot: 
				print("saved game not found, creating new player data")
			else: 
				print("saved game data found, loading into memory")
				var dataToParse = snapshot.content.get_string_from_utf8()
				currentData = JSON.parse_string(dataToParse)
	)

##PENGUINS##
func determinePenguins() -> void: 
	print("loading penguins")
	var penguin: Penguin = penguin_scene.instantiate()
	penguin.setLocation(300,1000)
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
	fish.fish_needs_target.connect(onGiveFishGoal)
	add_child(fish)
	onGiveFishGoal(fish)
	fishes.push_back(fish)
	
func determineFishIntelligence() -> void: 
	for f in fishes: 
		if f.hasGoal(): 
			f.moveToGoal()
			
##FOOD##
func determineFood() -> void: 
	print("loading food bowls")
	var food: Food = food_scene.instantiate()
	food.setLocation(550, 1050)
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

func onGiveFishGoal(fish) -> void: 
	print("giving an idle fish a goal")
	var randomGoalLocation = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
	fish.setGoal(randomGoalLocation.x, randomGoalLocation.y)
	fish.setState("Swim")

func onPenguinSelected(state) -> void: 
	penguinIsSelected = state
	print("penguin selected")

##EVENT LISTENERS##
func _on_ice_berg_area_area_entered(area: Area2D) -> void:
	print("something entered ice berg area")
	if area is Penguin:
		area.setCurrentArea("Ice")
		area.setState("Jump") 
		if not area.hasGoal(): 
			area.setState("Idle")
	
func _on_water_area_area_entered(area: Area2D) -> void:
	print("something entered water area")
	if area is Penguin:
		print("a penguin entered the water area")
		area.setState("Dive")
		area.setCurrentArea("Water")
		
func _on_water_area_area_exited(area: Area2D) -> void:
	print("something exited the water area")
	if area is Penguin: 
		print("a penguin exited the water area")
		#area.setState("Jump")
		area.setCurrentArea("Ice")
	
##GUI###
func handleDrag(pos: Vector2, delta: Vector2): 
	$Camera.position.x -= delta.x

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("location clicked")
		print("InputEventMouseButton")
		for p in penguins: 
			if p.selected: 
				print("controlling penguin")
				#var globalPosition = to_global(event.position)
				var globalPosition = $Camera.get_global_mouse_position()
				print("InputEvent -> x: " + str(globalPosition.x) + " y: " + str(globalPosition.y))
				p.setGoal(globalPosition.x, globalPosition.y)
				p.setSelected(false)
				if p.current_area == "Water": 
					p.setState("Swim")
				else: 
					p.setState("Walk")
	elif event is InputEventScreenDrag or event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print("InputEventScreenDrag or InputEventMouseMotion")
		#print("event position " + str(event.position.x))
		#print("event relative " + str(event.relative.x))
		handleDrag(event.position, event.relative)


func _on_fish_spawn_timer_timeout() -> void:
	#choose a new timeout
	print("fish spawn timeout")
	$FishSpawnTimer.wait_time = randf_range(8,15)
	var fish: Fish = fish_scene.instantiate()
	var randomSpawnLocation = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
	fish.setLocation(randomSpawnLocation.x, randomSpawnLocation.y)
	fish.fish_collected.connect(onFishCollected)
	fish.fish_needs_target.connect(onGiveFishGoal)
	add_child(fish)
	onGiveFishGoal(fish)
	fishes.push_back(fish)

func get_random_point_in_collision_polygon(collision_polygon: CollisionPolygon2D) -> Vector2:
	var points := collision_polygon.polygon
	var triangles := Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return collision_polygon.global_position
	var triangle_index := randi_range(0, triangles.size() / 3 - 1) * 3
	return points[triangles[triangle_index]]
