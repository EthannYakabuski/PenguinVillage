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
