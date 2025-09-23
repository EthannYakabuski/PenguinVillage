extends Node2D
@export var penguin_scene: PackedScene
@export var fish_scene: PackedScene
@export var food_scene: PackedScene
@export var gem_scene: PackedScene
@export var sidebar: PackedScene
@onready var fishTimer: Timer = $FishSpawnTimer

#UI interactions
var sidebarActive = false
var sidebarHandle
var isDragging = false

var penguins = []
var fishes = []
var foodBowls = []
#var foodBowl: Food

#random location optimizer
var lastPoints: Vector2

var penguinIsSelected = false

#google play integration
@onready var googleSignInClient: PlayGamesSignInClient = $Android_SignIn
@onready var googleSnapshotClient: PlayGamesSnapshotsClient = $Android_SavedGames
var currentData = ""

#signals
signal dataHasLoaded
signal penguinNeedsGoal

#admob integration
var _ad_view : AdView
var _rewarded_ad : RewardedAd
var _full_screen_content_callback : FullScreenContentCallback
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()

func _enter_tree() -> void: 
	GodotPlayGameServices.initialize()
	dataHasLoaded.connect(dataLoaded)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	androidAuthentication()
	admobConfiguration()
	penguinNeedsGoal.connect(onGivePenguinGoal)
	$DropControl.penguinDropped.connect(penguinIsDropped)
	$DropControl.foodDropped.connect(foodIsDropped)
	$DropControl.medicineDropped.connect(medicineIsDropped)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	determinePenguinIntelligence()
	determineFishIntelligence()

##SOCIAL CONNECTIONS##
func androidAuthentication() -> void: 
	if not GodotPlayGameServices.android_plugin: 
		printerr("Plugin not found")
		print(Time.get_datetime_dict_from_system())
		#create dummy data for testing
		var dummyData = {
			"Penguins": [{"health": 50, "food": 75, "sick": false}, {"health": 50, "food": 50, "sick": false}, {"health": 90, "food": 75, "sick": false}],
			"Food": [{"amount": 100, "locationX": 300, "locationY": 1150}],
			"Fish": [],
			"Decorations": [], 
			"AreasUnlocked": [false, false, false, false, false],
			"LastLogin": { "year": 2025, "month": 8, "day": 19, "weekday": 2, "hour": 23, "minute": 28, "second": 0, "dst": true },
			"DailyRewards": [true, false, false, false, false, false, false],
			"Gems": 250,
			"Coins": 100,
			"Experience": 1233
		}
		var jsonStringDummyData = JSON.stringify(dummyData)
		var jsonParsedDummyData = JSON.parse_string(jsonStringDummyData)
		PlayerData.setData(jsonParsedDummyData)
		emit_signal("dataHasLoaded")
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
func onAdInitializationComplete(_status : InitializationStatus): 
	print("banner ad initialization complete")
	_create_ad_view()
	
#code to call after data has been loaded from google store
func dataLoaded(): 
	print("loading screen")
	self.visible = true
	#$WaterArea.visible = true
	#$IceBergArea.visible = true
	determinePenguins()
	determineFish()
	determineFood()
	
#code to load banner ad
func _create_ad_view() -> void:
	#free memory
	if _ad_view:
		destroy_ad_view()

	#var adListener = AdListener.new()
	#adListener.on_ad_failed_to_load = func(load_ad_error : LoadAdError):
		pass 
	
	#var unit_id = "ca-app-pub-3940256099942544/6300978111"

	#_ad_view = AdView.new(unit_id, AdSize.BANNER, AdPosition.Values.TOP)
	#var ad_request = AdRequest.new()
	#_ad_view.load_ad(ad_request)
	#_ad_view.show()
	
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
		$Android_SavedGames.load_game("VillageData", false)
		$Android_SavedGames.game_loaded.connect(
		func(snapshot: PlayGamesSnapshot): 
			if !snapshot: 
				print("saved game not found, creating new player data")
				#create new player data
				var newLoginTime = Time.get_datetime_dict_from_system()
				print("newLoginTime: " + str(newLoginTime))
				var newPlayerData = {
					"Penguins": [{"health": 100, "food": 75, "sick": false}],
					"Food": [{"amount": 25, "locationX": 300, "locationY": 1150}],
					"Fish": [],
					"Decorations": [], 
					"AreasUnlocked": [false, false, false, false, false],
					"LastLogin": str(newLoginTime),
					"DailyRewards": [false, false, false, false, false, false, false],
					"Gems": 100,
					"Coins": 50,
					"Experience": 0
				}
				PlayerData.setData(newPlayerData)
				emit_signal("dataHasLoaded")
				var jsonNewPlayerData = JSON.stringify(newPlayerData)
				print(jsonNewPlayerData)
				PlayerData.saveData()
			else: 
				print("saved game data found, loading into memory")
				var dataToParse = snapshot.content.get_string_from_utf8()
				print(dataToParse)
				currentData = JSON.parse_string(dataToParse)
				PlayerData.setData(currentData)
				emit_signal("dataHasLoaded")
	)
##PENGUINS##
func determinePenguins() -> void: 
	print("loading penguins")
	#var penguin: Penguin = penguin_scene.instantiate()
	#penguin.setLocation(300,1000)
	#add_child(penguin)
	#penguins.push_back(penguin)
	var penguinsData = PlayerData.getData()["Penguins"]
	for penguinData in penguinsData: 
		var penguin: Penguin = penguin_scene.instantiate()
		var randomLocation = get_random_point_in_collision_polygon($IceBergArea/IceCollision)
		penguin.setLocation(randomLocation.x, randomLocation.y-300)
		penguin.setSick(penguinData["sick"])
		penguin.setHealth(penguinData["health"])
		penguin.setFood(penguinData["food"])
		penguin.penguinNeedsGoal.connect(onGivePenguinGoal)
		add_child(penguin)
		penguins.push_back(penguin)
		
	
func determinePenguinIntelligence() -> void: 
	#print("determining penguin intelligence")
	for p in penguins:
		if p.hasGoal():  
			p.moveToGoal()
		if p.getState() == "Idle": 
			if is_point_inside_polygon($IceMountainCollision, p.position): 
				print("there is an idle penguin in the iceberg slide")
				p.setState("Slide")
				onGivePenguinGoal(p)
		if p.getState() == "Eat":
			if p.health == 100 or foodBowls[0].foodLevel == 0:
				p.setState("Idle")
				updatePenguinAndFoodSavedArray() 
				pass
			else:
				p.addHealth(1)
				foodBowls[0].useFood(0.25)
			#onGivePenguinGoal(p)
			
##FISH##
func determineFish() -> void: 
	print("loading fish")
	var fish: Fish = fish_scene.instantiate()
	fish.setLocation(500, 1700)
	fish.fish_collected.connect(onFishCollected)
	fish.fish_needs_target.connect(onGiveFishGoal)
	fish.fish_danger_check.connect(onFishDanger)
	fish.fish_idle_needs_new_goal.connect(onGiveFishGoal)
	add_child(fish)
	onGiveFishGoal(fish)
	fishes.push_back(fish)
	
func determineFishIntelligence() -> void: 
	for f in fishes: 
		if f.hasGoal(): 
			f.moveToGoal()
			
func getThreatPosition(fish: Fish) -> Penguin: 
	var currentClosestPenguin
	var currentClosestDistance = 500
	for penguin in penguins: 
		if penguin.current_state == "Swim":
			var distance = penguin.global_position.distance_to(fish.global_position)
			if distance < 200: 
				if currentClosestDistance > distance:
					currentClosestPenguin = penguin
					currentClosestDistance = distance		
	return currentClosestPenguin
			
##FOOD##
func determineFood() -> void: 
	print("loading food bowls")
	#var food: Food = food_scene.instantiate()
	#food.setLocation(550, 1050)
	#add_child(food)
	#foodBowl = food
	#foodBowl.addFood(50)
	#foodBowls.push_back(food)
	var foodDatas = PlayerData.getData()["Food"]
	for foodData in foodDatas: 
		var food: Food = food_scene.instantiate()
		food.setLocation(foodData["locationX"], foodData["locationY"])
		food.addFood(foodData["amount"])
		foodBowls.push_back(food)
		add_child(food)

func updatePenguinAndFoodSavedArray(): 
	print("a penguin has finished eating, update saved data")
	var currData = PlayerData.getData()
	var newPenguins = []
	for p in penguins:
		newPenguins.push_back({"health": p.health, "food": p.food, "sick": p.sick}) 
	var newFood = []
	for f in foodBowls: 
		newFood.push_back({"amount": f.foodLevel, "locationX": f.global_position.x, "locationY": f.global_position.y})
	currData["Penguins"] = newPenguins
	currData["Food"] = newFood
	PlayerData.setData(currData)
	PlayerData.saveData()
	print("penguin data has been updated and saved to the cloud")
	print(PlayerData.getData())

##CUSTOM SIGNAL LISTENERS##
func onFishCollected(fish, penguin) -> void: 
	print("fish collected")
	if fish in fishes: 
		fishes.erase(fish)
		#TODO dynamically add food to the closest food bowl after a fish is caught
		foodBowls[0].addFood(10)
	fish.queue_free()
	penguin.addHealth(10)
	updatePenguinAndFoodSavedArray()

func onGivePenguinGoal(penguin) -> void: 
	print("giving a sliding penguin a new goal")
	var randomGoalLocation = get_random_point_in_collision_polygon($IceBergArea/IceCollision)
	penguin.setGoal(randomGoalLocation.x, randomGoalLocation.y)
	penguin.startTime()
	#penguin.setState("Walk")

func onGiveFishGoal(fish) -> void: 
	#print("giving an idle fish a goal")
	var randomGoalLocation = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
	fish.setGoal(randomGoalLocation.x, randomGoalLocation.y)
	fish.setState("Swim")
	
func onFishDanger(fish) -> void: 
	var closestPenguin = getThreatPosition(fish)
	if closestPenguin: 
		var directionToDanger = fish.global_position.direction_to(Vector2(closestPenguin.global_position.x, closestPenguin.global_position.y))
		var escapeDirection = -directionToDanger.normalized()
		#print("fish in danger")
		fish.setThreat("danger")
		fish.setSpeed(3.0)
		var fleeDistance = 150.0
		var fleeTarget = fish.global_position + (escapeDirection * fleeDistance)
		var dangerDirection
		if directionToDanger.x > 0: 
			dangerDirection = "right"
		else:
			dangerDirection = "left"
		if is_point_inside_polygon($WaterArea/WaterCollision, fleeTarget):
			#print("found a default candidate")
			if not fish.hasGoal():
				fish.setGoal(fleeTarget.x, fleeTarget.y)
		else: 
			#find a random point in the pond, that is also away from the penguin
			for i in range(10): 
				#print("trying to find a candidate")
				var candidate = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
				var candidateDirection = fish.global_position.direction_to(candidate)
				var candidateDirectionString
				if candidateDirection.x > 0: 
					candidateDirectionString = "right"
				else: 
					candidateDirectionString = "left"
				if dangerDirection == candidateDirectionString: 
					#print("found a working candidate")
					if not fish.hasGoal(): 
						fish.setGoal(candidate.x, candidate.y)
					return
			print("unable to find a flee target")
	else: 
		fish.setThreat("safe")

func onPenguinSelected(state) -> void: 
	penguinIsSelected = state
	print("penguin selected")

##EVENT LISTENERS##
func _on_ice_berg_area_area_entered(area: Area2D) -> void:
	print("something entered ice berg area")
	if area is Penguin:
		area.setCurrentArea("Ice")
		area.setState("Jump") 
		area.stopTime()
		if not area.hasGoal(): 
			area.setState("Idle")
	
func _on_water_area_area_entered(area: Area2D) -> void:
	print("something entered water area")
	if area is Penguin:
		print("a penguin entered the water area")
		area.setState("Dive")
		area.setCollisionGons("Swim")
		area.setCurrentArea("Water")
		
func _on_water_area_area_exited(area: Area2D) -> void:
	print("something exited the water area")
	if area is Penguin: 
		print("a penguin exited the water area")
		area.setCollisionGons("Walk")
		area.setCurrentArea("Ice")
	
##GUI###
func handleDrag(_pos: Vector2, delta: Vector2): 
	$Camera.position.x -= delta.x
	
func penguinIsDropped(): 
	print("penguin has been dropped and received")
	#spawn the penguin into the scene + animation
	#update the players cloud data
	isDragging = false
	
func medicineIsDropped(): 
	print("medicine has been dropped and received")
	#find the closest sick penguin
	#heal the penguin + play animation
	#update the players cloud data
	isDragging = false
	
func foodIsDropped(): 
	print("food has been dropped and received")
	#feed all penguins + play animation
	#fill all food bowls 
	#update the players cloud data
	isDragging = false
	
func dragToggle(): 
	print("there is an item being dragged from the sidebar")
	isDragging = true

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
		#if we arent currently dragging an element from the sidebar, we are dragging the camera view
		if !isDragging: 
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
	fish.fish_idle_needs_new_goal.connect(onGiveFishGoal)
	fish.fish_danger_check.connect(onFishDanger)
	add_child(fish)
	onGiveFishGoal(fish)
	fishes.push_back(fish)
	
func _on_gem_spawn_timer_timeout() -> void:
	print("gem spawn timeout")
	$GemSpawnTimer.wait_time = randf_range(10,20)
	var gem = gem_scene.instantiate()
	var randomSpawn = get_random_point_in_collision_polygon($IceMountainCollision)
	gem.global_position = randomSpawn
	add_child(gem)

func get_random_point_in_collision_polygon(collision_polygon: CollisionPolygon2D) -> Vector2:
	var points := collision_polygon.polygon
	var triangles := Geometry2D.triangulate_polygon(points)
	if triangles.is_empty():
		return collision_polygon.global_position
	var triangle_index := randi_range(0, triangles.size() / 3-1) * 3
	return points[triangles[triangle_index]]
	
func is_point_inside_polygon(collision_polygon: CollisionPolygon2D, point: Vector2) -> bool:
	var local_point = collision_polygon.get_global_transform().affine_inverse() * point
	return Geometry2D.is_point_in_polygon(local_point, collision_polygon.polygon)


func _on_side_bar_pressed() -> void:
	print("side bar pressed")
	if not sidebarActive: 
		sidebarHandle = sidebar.instantiate()
		sidebarHandle.isDraggingSignal.connect(dragToggle)
		$CanvasMenu.add_child(sidebarHandle)
		sidebarActive = true
	else: 
		$CanvasMenu.remove_child(sidebarHandle)
		sidebarActive = false
