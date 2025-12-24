extends Node2D
@export var penguin_scene: PackedScene
@export var fish_scene: PackedScene
@export var food_scene: PackedScene
@export var gem_scene: PackedScene
@export var experienceShard_scene: PackedScene
@export var sidebar: PackedScene
@export var modalDialog: PackedScene
@export var modalDailyDialog: PackedScene
@export var tutorialDialog: PackedScene
@export var gemShard_scene: PackedScene
@onready var fishTimer: Timer = $FishSpawnTimer
const controlItemScript = preload("res://scripts/sidebaritem.gd")

#UI interactions
var isTutorialCompleted = true
var tutorialProgress = 0
var sidebarActive = false
var sidebarHandle
var isDragging = false
var levelUpDialog
var dailyDialog
var tutDialog
var loading = true
var currentDragDelta = 0

var pressing = false
var pressStartTime = 0.0
var pressPos = Vector2.ZERO

var penguins = []
var fishes = []
var foodBowls = []
var gems = []
#var foodBowl: Food

#random location optimizer
var lastPoints: Vector2

var currentPenguinPrice = 50
var currentFoodPrice = 100
var currentMedicinePrice = 75
var currentPenguinFoodReqSinceLastLogin = 0

var lastLogin_global

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
	randomize()
	penguinNeedsGoal.connect(onGivePenguinGoal)
	$DropControl.penguinDropped.connect(penguinIsDropped)
	$DropControl.foodDropped.connect(foodIsDropped)
	$DropControl.medicineDropped.connect(medicineIsDropped)
	$DropControl.newBowlDropped.connect(newBowlIsDropped)
	$DropControl.existingBowlDragged.connect(existingBowlDropped)
	#prepare the sidebar handle so that we can accept level up prizes and keep track of
	#current penguin cost even before the player has explicitly toggled the sidebar
	sidebarHandle = sidebar.instantiate()
	sidebarHandle.isDraggingSignal.connect(dragToggle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	determinePenguinIntelligence()
	determineFishIntelligence()
	if(loading): 
		$LoadingBar.value = $LoadingBar.value + 1
	
func playCorrectMusic() -> void: 
	if lastLogin_global["hour"] >= 17:
		$Camera/MainMusic_Evening.play()
	else:
		$Camera/MainMusic.play() 
		
##SOCIAL CONNECTIONS##
func androidAuthentication() -> void: 
	if not GodotPlayGameServices.android_plugin: 
		printerr("Plugin not found")
		print(Time.get_datetime_dict_from_system())
		#create dummy data for testing
		lastLogin_global = { "year": 2025, "month": 12, "day": 21, "weekday": 0, "hour": 7, "minute": 0, "second": 0, "dst": true }
		var dummyData = {
			"Penguins": [{"health": 50, "food": 100, "sick": false},{"health": 50, "food": 100, "sick": false},{"health": 50, "food": 75, "sick": true}],
			"Food": [{"amount": 100, "locationX": 300, "locationY": 1150}],
			"Fish": [],
			"Decorations": [], 
			"Inventory": [0,0,0],
			"AreasUnlocked": [false, false, false, false, false],
			"LastLogin": { "year": 2025, "month": 12, "day": 21, "weekday": 0, "hour": 7, "minute": 0, "second": 0, "dst": true },
			"DailyRewards": [true, true, true, true, true, true, true],
			"DailyRewardsClaimed": [false, false, false, false, false, false, false],
			"Gems": 1050,
			"Coins": 100,
			"Experience": 1287, 
			"LevelExperience": 70,
			"PlayerLevel": 1,
			"FishCaught": 0,
			"TutorialCompleted": false,
			"TutorialProgress": 0,
		}
		var jsonStringDummyData = JSON.stringify(dummyData)
		var jsonParsedDummyData = JSON.parse_string(jsonStringDummyData)
		PlayerData.setData(jsonParsedDummyData)
		#updateLastLogin()
		#simulates connection time to load players saved data in a real device
		await get_tree().create_timer(2.0).timeout
		emit_signal("dataHasLoaded")
	else: 
		print("Plugin found")
	googleSignInClient.is_authenticated()
	
func admobConfiguration() -> void: 
	var onInitializationCompleteListener = OnInitializationCompleteListener.new()
	onInitializationCompleteListener.on_initialization_complete = onAdInitializationComplete
	var request_configuration = RequestConfiguration.new()
	#Comply with Google Play families policy and COPPA
	request_configuration.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
	#Keeps ad content rating safe for kids
	request_configuration.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G
	
	if MobileAds: 
		MobileAds.set_request_configuration(request_configuration)
		MobileAds.initialize(onInitializationCompleteListener)
		
#called after admob init is complete, loads a banner ad
func onAdInitializationComplete(_status : InitializationStatus): 
	print("banner ad initialization complete")
	_create_ad_view()
	
#code to call after data has been loaded from google store
func dataLoaded(): 
	print("loading screen")
	loading = false
	makeEverythingVisible()
	$LoadingBar.visible = false
	#$WaterArea.visible = true
	#$IceBergArea.visible = true
	updateLastLogin()
	determineFish()
	determineFood()
	determinePenguins()
	updateGemsLabel(PlayerData.getData()["Gems"])
	updateExperienceBar(PlayerData.getData()["Experience"])
	determineDailyReward()
	calculateCurrentPenguinPrice()
	spawnInitialGemsAndFish()
	checkTutorialProgress()
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
		on_user_earned_reward_listener.on_user_earned_reward = on_user_earned_reward
		showMermaidButton()
	
	var ad_request = AdRequest.new()
	#makes sure that served ads are not personalized to the user
	ad_request.extras["npa"] = "1"
	RewardedAdLoader.new().load(unit_id, ad_request, rewarded_ad_load_callback)
	
func makeEverythingVisible() -> void: 
	$CanvasMenu.visible = true
	$WaterArea.visible = true
	$IceBergArea.visible = true
	
func updateTutorialProgress(progress) -> void: 
	var currData = PlayerData.getData()
	currData["TutorialProgress"] = int(progress)
	PlayerData.setData(currData)
	PlayerData.saveData()

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

func showMermaidButton(): 
	$MermaidButton.visible = true

func loadAchievements(): 
	if $AchievementsClient: 
		$AchievementsClient.show_achievements()
	
func loadLeaderboards(): 
	if $LeaderboardsClient:
		$LeaderboardsClient.show_all_leaderboards()
		
#code to launch a rewarded ad, triggered manually by player
func _on_ad_button_pressed() -> void:
	_rewarded_ad.full_screen_content_callback = _full_screen_content_callback
	_rewarded_ad.show(on_user_earned_reward_listener)
	$MermaidButton.visible = false
		
#called after user watches the manually launched rewarded ad
func on_user_earned_reward(rewarded_item : RewardedItem):
	print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	#once we are using an actual unit-id from admob, the rewarded_item.amount and rewarded_item.type values are set in the admob console
	var currData = PlayerData.getData()
	currData["Gems"] = currData["Gems"] + 50
	addGemIndicator(50, $MermaidButton.position)
	#Gem master incremental achievement increment
	$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQDQ", 50)
	#Highest Gem Count leaderboard score submit
	$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBA", currData["Gems"])
	updateGemsLabel(currData["Gems"])
	#Supporter achievement
	$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQDA")
	PlayerData.setData(currData)
	PlayerData.saveData()
	
func determineDailyReward():
	print("inside determineDailyReward") 
	var weekday = lastLogin_global["weekday"]
	print("determining daily reward it is weekday: " + str(weekday))
	if not PlayerData.getData()["DailyRewardsClaimed"][weekday]: 
		print("todays daily reward has not yet been claimed")
		$DailyRewardBox.visible = true
	else: 
		print("todays daily reward has already been claimed")
	
func _on_daily_reward_box_pressed() -> void:
	print("collecting daily reward from clicking on the present")
	$Camera/GemCollectedSound.play()
	dailyDialog = modalDailyDialog.instantiate()
	dailyDialog.rewardAccepted.connect(levelUpPrizeAccepted)
	var currData = PlayerData.getData()
	var rewardsClaimed = currData["DailyRewards"]
	var currentDay = lastLogin_global["weekday"]
	var subsequentTruesBehindCurrentDay = 0
	var keepLooping = true
	var loopVar = currentDay
	while keepLooping: 
		if rewardsClaimed[(loopVar - 1) % 7]: 
			print("incrementing streak")
			subsequentTruesBehindCurrentDay += 1
			if subsequentTruesBehindCurrentDay == 6:
				break
			loopVar -= 1
		else: 
			print("stopping loop")
			keepLooping = false
	if subsequentTruesBehindCurrentDay == 6: 
		print("player has logged in for a week straight, resetting arrays")
		#Daily grind achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQEg")
		currData["DailyRewards"] = [false, false, false, false, false, false, false]
		currData["DailyRewards"][currentDay] = true
	var totalConsecutiveDays = subsequentTruesBehindCurrentDay + 1
	print("the total number of consecutive days is: " + str(totalConsecutiveDays))
	dailyDialog.setCurrentDay(totalConsecutiveDays)
	$CanvasMenu.add_child(dailyDialog)
	#need to reset all other days of the DailyRewardsClaimed array to false
	currData["DailyRewardsClaimed"] = [false, false, false, false, false, false, false]
	currData["DailyRewardsClaimed"][currentDay] = true
	#var gemsToCollect = 40 + 15*totalConsecutiveDays + 5*(totalConsecutiveDays*totalConsecutiveDays)
	#print("The player will collect " + str(gemsToCollect) + " gems")
	#currData["Gems"] = currData["Gems"] + gemsToCollect
	#$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBA", currData["Gems"])
	#$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQDQ", gemsToCollect)
	#updateGemsLabel(currData["Gems"])
	$DailyRewardBox.visible = false
	PlayerData.setData(currData)
	PlayerData.saveData()

##GOOGLE PLAY GAME SERVICES##
func _on_user_authenticated(is_authenticated: bool) -> void:
	print("Hi from Godot! User is authenticated? %s" % is_authenticated)
	var newLoginTime = Time.get_datetime_dict_from_system()
	lastLogin_global = newLoginTime
	if is_authenticated: 
		$Android_SavedGames.load_game("VillageData", false)
		$Android_SavedGames.game_loaded.connect(
		func(snapshot: PlayGamesSnapshot): 
			if !snapshot: 
				print("saved game not found, creating new player data")
				#create new player data
				print("newLoginTime: " + str(newLoginTime))
				var newPlayerData = {
					"Penguins": [{"health": 100, "food": 75, "sick": false}],
					"Food": [{"amount": 25, "locationX": 300, "locationY": 1150}],
					"Fish": [],
					"Decorations": [], 
					"Inventory": [0,0,0],
					"AreasUnlocked": [false, false, false, false, false],
					"LastLogin": newLoginTime,
					"DailyRewards": [false, false, false, false, false, false, false],
					"DailyRewardsClaimed" : [false, false, false, false, false, false, false],
					"Gems": 100,
					"Coins": 50,
					"Experience": 0, 
					"LevelExperience": 0,
					"PlayerLevel": 1, 
					"FishCaught": 0,
					"TutorialCompleted": false,
					"TutorialProgress": 0,
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
	
##updates players last login time
func updateLastLogin() -> void: 
	var currData = PlayerData.getData()
	var newestLogin = Time.get_datetime_dict_from_system()
	lastLogin_global = newestLogin
	playCorrectMusic()
	calculatePenguinDamageFromLastLogin(currData["LastLogin"], newestLogin)
	currData["LastLogin"] = newestLogin
	#print(Time.get_datetime_dict_from_system()["weekday"])
	currData["DailyRewards"][Time.get_datetime_dict_from_system()["weekday"]] = true
	PlayerData.setData(currData)
	PlayerData.saveData()

func checkTutorialProgress() -> void: 
	isTutorialCompleted = PlayerData.getData()["TutorialCompleted"]
	if not isTutorialCompleted: 
		tutorialProgress = PlayerData.getData()["TutorialProgress"]
		print("starting tutorial")
		if not tutDialog: 
			tutDialog = tutorialDialog.instantiate()
	match int(tutorialProgress):
		0: 
			print("tutorial move penguin")
			penguins[0].setLocation(400,1000)
			tutDialog.setDialogText("Hey, my name is Jerome, nice to meet you. I will teach you the basic controls for just a few minutes. Try clicking on a penguin to activate it")
			$CanvasMenu.add_child(tutDialog)
		1: 
			print("tutorial catch fish")
			tutDialog.setDialogText("That's it! You can also catch fish. Hop in the water and see if you can catch a fish! Catching fish will fill up your food bowl.")
		2: 
			print("tutorial eat food")
			tutDialog.setDialogText("Good catch! Making your penguin move around will use its energy. Move the penguin beside the food bowl to make it eat and restore its energy!")
		3: 
			print("tutorial collect a gem")
			tutDialog.moveYAxisDown()
			tutDialog.setDialogText("Well done! You can also use your penguins to collect purple gems, which are used to purchase helpful items. Can you collect a gem?")
		4: 
			print("tutorial buy new penguin")
			tutDialog.setDialogText("Good job! Let's use some of those gems to purchase a new penguin. Click the menu button in the top left corner to activate the sidebar")
		5: 
			print("tutorial heal sick penguin")
			penguins[0].setSick(true)
			tutDialog.setDialogText("Good work! Now it looks like one of your penguins is sick (painted green). Can you drag and drop the medicine icon to heal the penguin?")
			tutDialog.moveYAxisUp()
		6: 
			print("tutorial completed")
			tutDialog.makeButtonVisible()
			var currData = PlayerData.getData()
			currData["TutorialCompleted"] = true
			PlayerData.setData(currData)
			PlayerData.saveData()
			tutDialog.setDialogText("Nicely done, you have completed the tutorial!")
		
##PENGUINS##
func calculatePenguinDamageFromLastLogin(lastLogin, currentLogin): 
	#print(lastLogin)
	#print(currentLogin)
	var lastLogin_unix = Time.get_unix_time_from_datetime_dict(lastLogin)
	#print(lastLogin_unix)
	var currentLogin_unix = Time.get_unix_time_from_datetime_dict(currentLogin)
	var timeInSecondsSinceLastLogin = currentLogin_unix - lastLogin_unix
	print("time in seconds since last login " + str(timeInSecondsSinceLastLogin))
	#it has been more than a day since last login, reset the entire daily rewards array
	if timeInSecondsSinceLastLogin > 86400:
		print("it has been more than a day since last login, clearing the daily rewards array") 
		var currData = PlayerData.getData()
		for day in range(7): 
			currData["DailyRewards"][day] = false
			currData["DailyRewardsClaimed"][day] = false
		PlayerData.setData(currData)
		PlayerData.saveData()
	var days = int(timeInSecondsSinceLastLogin / 86400.0)
	var hours = int((timeInSecondsSinceLastLogin % 86400) / 3600.0)
	var minutes = int((timeInSecondsSinceLastLogin % 3600) / 60.0)
	updatePenguinsFoodLevelsSinceLastLogin(days, hours, minutes)
	
func updatePenguinsFoodLevelsSinceLastLogin(days: int, hours: int, minutes: int): 
	var foodRequired = int((days * 30) + (hours * 1.25) + (minutes * 0.17))
	print("foodRequired: " + str(foodRequired))
	currentPenguinFoodReqSinceLastLogin = foodRequired

func spawnInitialGemsAndFish() -> void: 
	for i in range(5): 
		_on_fish_spawn_timer_timeout()
	for i in range(5): 
		_on_gem_spawn_timer_timeout()

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
		penguin.setLocation(randomLocation.x, randomLocation.y - 150)
		penguin.setSick(penguinData["sick"])
		penguin.setHealth(penguinData["health"])
		penguin.setFood(penguinData["food"])
		penguin.penguinNeedsGoal.connect(onGivePenguinGoal)
		add_child(penguin)
		penguins.push_back(penguin)
	for penguin in penguins: 
		print("penguin using energy from app being idle")
		penguin.useEnergy(currentPenguinFoodReqSinceLastLogin)
	updatePenguinAndFoodSavedArray()
		
func addPenguinAtLocation(atPosition: Vector2) -> void: 
	var penguin: Penguin = penguin_scene.instantiate()
	penguin.setLocation(atPosition.x, atPosition.y)
	penguin.setHealth(100)
	penguin.setFood(100)
	penguin.penguinNeedsGoal.connect(onGivePenguinGoal)
	add_child(penguin)
	#this is set after the penguin is added to the scene in order for the sick timer to launch correctly
	penguin.setSick(false)
	penguins.push_back(penguin)
	
func getClosestFoodBowlToThisPenguin(penguin: Penguin) -> Food:
	#assume closest bowl is bowl0
	var currentClosestBowl = foodBowls[0]
	var currentMinimumDistance = 999999999
	for bowl in foodBowls: 
		var thisBowlDistance = bowl.getLocation().distance_squared_to(penguin.global_position)
		print(thisBowlDistance)
		if thisBowlDistance < currentMinimumDistance: 
			currentClosestBowl = bowl
			currentMinimumDistance = thisBowlDistance
	return currentClosestBowl
	
func determinePenguinIntelligence() -> void: 
	#print("determining penguin intelligence")
	for p in penguins:
		if p.hasGoal():  
			p.moveToGoal()
		if p.getState() == "Idle": 
			if is_point_inside_polygon($IceMountainArea/IceMountainCollision, p.position): 
				print("there is an idle penguin in the iceberg slide")
				p.setState("Slide")
				onGivePenguinGoal(p)
		if p.getState() == "Eat":
			var foodBowlToInteractWith = getClosestFoodBowlToThisPenguin(p)
			if p.food == 100 or foodBowlToInteractWith.foodLevel == 0:
				p.setState("Idle")
				updatePenguinAndFoodSavedArray() 
				pass
			else:
				p.addFood(1)
				if not isTutorialCompleted and int(tutorialProgress) == 2:
					updateTutorialProgress(3)
					checkTutorialProgress()
				p.stopStepSound()
				if not $Camera/FoodEatSound.playing: 
					$Camera/FoodEatSound.play()
				#Master Chef achievement
				$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQBw", 1)
				foodBowlToInteractWith.useFood(0.25)
			#onGivePenguinGoal(p)
			
##FISH##
func determineFish() -> void: 
	print("loading fish")
	var fish: Fish = fish_scene.instantiate()
	fish.setType("blue")
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
			if f.current_area == "Ice": 
				pass
				#onGiveFishGoal(f)
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
		#var foodControl = Control.new()
		#foodControl.set_script(controlItemScript)
		#foodControl.setControlItemType("FoodBowlDrag")
		#foodControl.position = Vector2(foodData["locationX"], foodData["locationY"])
		#foodControl.controlItemType = "FoodBowlDrag"
		var food: Food = food_scene.instantiate()
		#foodControl.size = Vector2(400, 400)
		food.setLocation(foodData["locationX"], foodData["locationY"])
		food.addFood(foodData["amount"])
		foodBowls.push_back(food)
		add_child(food)
		#foodControl.add_child(food)
		#add_child(foodControl)

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
	if not isTutorialCompleted and int(tutorialProgress) == 1: 
		updateTutorialProgress(2)
		checkTutorialProgress()
	$Camera/FishCaughtSound.play()
	if fish in fishes: 
		fishes.erase(fish)
		for bowl in foodBowls: 
			bowl.addFood(10)
	fish.queue_free()
	penguin.addHealth(10)
	var currData = PlayerData.getData()
	currData["FishCaught"] = currData["FishCaught"] + 1
	#total fish caught leaderboard score update
	$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQAQ", currData["FishCaught"])
	#catch a fish achivement
	$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQAg")
	#catch 1000 fish achievement increment (Fishing Master achievement)
	$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQBg", 1)
	if fish.getType() == "purple": 
		currData["Gems"] = currData["Gems"] + 10
		givePlayerExperience(10, fish.global_position)
		addGemIndicator(10, Vector2(fish.global_position.x+50,fish.global_position.y))
		#collect 2500 gems achievement increment (Gem Master incremental achievement increment)
		$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQDQ", 10)
		#Highest Gem Count leaderboard score submit
		$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBA", currData["Gems"])
		updateGemsLabel(currData["Gems"])
		#Purple fish achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQCw")
	if fish.getType() == "gold": 
		#Golden fish achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQCg")
		givePlayerExperience(50, fish.global_position)
	if fish.getType() == "blue": 
		givePlayerExperience(5, fish.global_position)
	PlayerData.setData(currData)
	PlayerData.saveData()
	print("gem has been collected, and data has been saved to the cloud")
	updatePenguinAndFoodSavedArray()
	
func onGemCollected(gem) -> void: 
	print("gem collected")
	if not isTutorialCompleted and int(tutorialProgress) == 3: 
		updateTutorialProgress(4)
		checkTutorialProgress()
	if gem in gems: 
		gems.erase(gem)
	gem.queue_free()
	var currData = PlayerData.getData()
	currData["Gems"] = currData["Gems"] + 5
	givePlayerExperience(5, gem.global_position)
	addGemIndicator(5, Vector2(gem.global_position.x+50,gem.global_position.y))
	#Gem master incremental achievement increment
	$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQDQ", 5)
	#Highest Gem Count leaderboard score submit
	$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBA", currData["Gems"])
	updateGemsLabel(currData["Gems"])
	PlayerData.setData(currData)
	PlayerData.saveData()
	$Camera/GemCollectedSound.play()
	print("gem has been collected, and data has been saved to the cloud")
	print(PlayerData.getData())

func onGivePenguinGoal(penguin) -> void: 
	print("giving a sliding penguin a new goal")
	var randomGoalLocation = get_random_point_in_collision_polygon($IceBergArea/IceCollision)
	penguin.setGoal(randomGoalLocation.x, randomGoalLocation.y-100)
	penguin.startTime()
	#penguin.setState("Walk")

func onGiveFishGoal(fish) -> void: 
	#print("giving an idle fish a goal")
	var randomGoalLocation = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
	fish.setGoal(randomGoalLocation.x, randomGoalLocation.y)
	fish.setState("Swim")

func spendGems(gemsSpent) -> void: 
	var currData = PlayerData.getData()
	currData["Gems"] = currData["Gems"] - gemsSpent
	updateGemsLabel(currData["Gems"])
	PlayerData.setData(currData)
	PlayerData.saveData()
	
func givePlayerExperience(amount, location) -> void: 
	print("giving player " + str(amount) + "experience")
	addIndicator(amount, location)
	var doubleLevel = false
	var singleLevel = false
	var currData = PlayerData.getData()
	var currentPlayerLevel = currData["PlayerLevel"]
	var currentTotalExperience = currData["Experience"]
	var currentLevelExperience = currData["LevelExperience"]
	var currentTotalExperienceToLevelUp = calculateExperienceRequiredForLevelUp(currentPlayerLevel)
	
	currentTotalExperience = currentTotalExperience + amount
	currentLevelExperience = currentLevelExperience + amount
	
	#the maximum xp that can be given to a player at one time is 100, when buying a new penguin
	#the player has leveled up
	if currentLevelExperience >= currentTotalExperienceToLevelUp:
		print("player has leveled up")
		$Camera/LevelUpSound.play()
		singleLevel = true
		currentPlayerLevel = currentPlayerLevel + 1
		currentLevelExperience = currentLevelExperience - currentTotalExperienceToLevelUp
		#it is possible the player has leveled up more than once during this action, but not more than twice
		var doubleLevelUpExpNeeded = calculateExperienceRequiredForLevelUp(currentPlayerLevel)
		if currentLevelExperience >= doubleLevelUpExpNeeded: 
			print("the player has leveled up again")
			doubleLevel = true
			currentPlayerLevel = currentPlayerLevel + 1
			currentLevelExperience = currentLevelExperience - doubleLevelUpExpNeeded
	
	if singleLevel or doubleLevel: 
		levelUpDialog = modalDialog.instantiate()
		levelUpDialog.prizeAccepted.connect(levelUpPrizeAccepted)
		levelUpDialog.setDisplayedLevel(currentPlayerLevel, doubleLevel)
		$CanvasMenu.add_child(levelUpDialog)
			
	#add_child(levelUpDialog) 
	var afterLevelUpExperienceRequired = calculateExperienceRequiredForLevelUp(currentPlayerLevel)
	updateExperienceBarLocal(str(currentPlayerLevel), int(currentLevelExperience), int(afterLevelUpExperienceRequired))
	currData["PlayerLevel"] = currentPlayerLevel
	currData["Experience"] = currentTotalExperience
	#Total Experience leaderboard score submit
	$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBQ", currentTotalExperience)
	currData["LevelExperience"] = currentLevelExperience
	if currentPlayerLevel >= 50: 
		#level 50 achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQFw")
	if currentPlayerLevel >= 30: 
		#level 30 achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQFg")
	if currentPlayerLevel >= 20: 
		#level 20 achievement 
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQFQ")
	if currentPlayerLevel >= 10: 
		#level 10 achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQFA")
	if currentPlayerLevel >= 5: 
		#level 5 achievement
		$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQEw")
	
	PlayerData.setData(currData)
	PlayerData.saveData()
	
func toggleFoodBowlAction(enabled: bool) -> void: 
	for bowl in foodBowls:
		if enabled:  
			bowl.mouse_filter = Control.MOUSE_FILTER_STOP 
		else: 
			bowl.mouse_filter = Control.MOUSE_FILTER_IGNORE

func levelUpPrizeAccepted(gemsGained, penguinsGained, foodGained, medicineGained) -> void: 
	print("prize accepted in main")
	$Camera/GemCollectedSound.play()
	var currData = PlayerData.getData()
	currData["Gems"] = currData["Gems"] + int(gemsGained)
	currData["Inventory"][0] = currData["Inventory"][0] + penguinsGained
	currData["Inventory"][1] = currData["Inventory"][1] + foodGained
	currData["Inventory"][2] = currData["Inventory"][2] + medicineGained
	if sidebarActive: 
		sidebarHandle.setCurrentPenguinInventory(currData["Inventory"][0])
		sidebarHandle.setCurrentFoodInventory(currData["Inventory"][1])
		sidebarHandle.setCurrentMedicineInventory(currData["Inventory"][2])
	#Highest Gem Count leaderboard score submit
	$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQBA", currData["Gems"])
	#Gem master incremental achievement increment
	$AchievementsClient.increment_achievement("CgkI8tzE1rMcEAIQDQ", gemsGained)
	updateGemsLabel(currData["Gems"])
	PlayerData.setData(currData)
	PlayerData.saveData()
	calculateCurrentPenguinPrice()
	levelUpDialog = null

func addIndicator(amount, positionOfShard): 
	var newIndicator = experienceShard_scene.instantiate()
	newIndicator.position = positionOfShard
	newIndicator.setLabel(amount)
	add_child(newIndicator)
	newIndicator.startTimer()
	
func addGemIndicator(amount, positionOfShard): 
	var newIndicator = gemShard_scene.instantiate()
	newIndicator.position = positionOfShard
	newIndicator.setLabel(amount)
	add_child(newIndicator)
	newIndicator.startTimer()
	
func calculateExperienceRequiredForLevelUp(level) -> int: 
	var calculatedExactXp = 50 + 2 * pow(float(level - 1), 1.75)
	var roundedXp = int(round(calculatedExactXp / 5.0) * 5.0)
	print(roundedXp)
	return roundedXp
	
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
	if not isTutorialCompleted and tutorialProgress == 0: 
		print("tutorial: select penguin success")
		tutDialog.setDialogText("Good! Now click anywhere else to make the penguin waddle over")

func foodBowlHeld(theBowl) -> void: 
	print("food bowl has been held ")
	isDragging = true
	
func onPenguinDied() -> void: 
	#Penguin Mortician achievement
	$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQCQ")
	for i in range(penguins.size() -1, -1, -1): 
		var penguin = penguins[i]
		if penguin.current_state == "Dead": 
			#penguin.queue_free()
			penguins.remove_at(i)
			penguin.initiateDeath()
	print(penguins)
	updatePenguinAndFoodSavedArray()
			
##EVENT LISTENERS##
func _on_ice_berg_area_area_entered(area: Area2D) -> void:
	#print("something entered ice berg area")
	if area is Penguin:
		area.setCurrentArea("Ice")
		area.setState("Jump") 
		area.stopTime()
		if not area.hasGoal(): 
			area.setState("Idle")
	elif area is Fish: 
		#print("a fish has come too close to the iceberg, finding a new goal")
		area.current_area = "Ice"
		area.goal = area.goal * Vector2(-1,1)
		#area.hasAGoal = false
		#onGiveFishGoal(area)
		
func _on_ice_berg_area_area_exited(area: Area2D) -> void:
	if area is Fish: 
		area.current_area = "Water"
	
func _on_water_area_area_entered(area: Area2D) -> void:
	#print("something entered water area")
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
		
func doesIceMountainHaveThisPenguin(penguin: Penguin) -> bool: 
	if $IceMountainArea.get_overlapping_areas().has(penguin): 
		return true
	else:
		return false

func doesWaterAreaHaveThisPenguin(penguin: Penguin) -> void: 
	if $WaterArea.get_overlapping_areas().has(penguin): 
		print("penguin is in fact in the water area, setting to swim")
		penguin.setCurrentArea("Water")
		penguin.setState("Swim")

func doesIceAreaHaveThisPenguin(penguin: Penguin) -> void: 
	if $IceBergArea.get_overlapping_areas().has(penguin): 
		print("penguin is in fact in the ice area, setting to walk if it has a goal")
		penguin.setCurrentArea("Ice")
		penguin.stopTime()
		if penguin.hasGoal(): 
			penguin.setState("Walk")
		else: 
			penguin.setState("Idle")
	
##GUI###
func handleDrag(_pos: Vector2, delta: Vector2):
	#var originalCameraX = $Camera.position.x 
	var proposedPosition = $Camera.position.x - delta.x
	var clamped = clamp(proposedPosition, $Camera.limit_left, $Camera.limit_right)
	$Camera.position.x += (clamped - $Camera.position.x)
	#var finalCameraX = $Camera.position.x
	#var finalActualDelta = originalCameraX - finalCameraX
	#currentDragDelta = currentDragDelta + finalActualDelta
	#print("setting current camera drag delta to " + str(currentDragDelta))
	
func getCamera() -> Camera2D: 
	return $Camera
	
func updateGemsLabel(amount): 
	$CanvasMenu/GemIndicator/GemLabel.text = str(int(amount))
	
func updateExperienceBar(_experience): 
	var totalExperienceRequiredForLevelUp = calculateExperienceRequiredForLevelUp(PlayerData.getData()["PlayerLevel"])
	updateExperienceBarLocal(str(PlayerData.getData()["PlayerLevel"]), PlayerData.getData()["LevelExperience"], totalExperienceRequiredForLevelUp)
	
func updateExperienceBarLocal(level, currentExperience, totalExperienceRequired):
	print("level " + level)
	print("currentExperience " + str(currentExperience))
	print("totalExperienceRequired " + str(totalExperienceRequired))
	$CanvasMenu/LevelLabel.text = str(int(level))
	var currentPercentage = (float(currentExperience) / float(totalExperienceRequired)) * 100
	$CanvasMenu/LevelBar.value = currentPercentage
	print("setting experience bar to " + str(currentPercentage))
	
func penguinIsDropped(_atPosition: Vector2): 
	print("penguin has been dropped and received")
	if not isTutorialCompleted and int(tutorialProgress) == 4: 
		updateTutorialProgress(5)
		checkTutorialProgress()
	#spawn the penguin into the scene + animation
	#update the players cloud data
	var globalPosition = $Camera.get_global_mouse_position()
	if PlayerData.getData()["Gems"] >= currentPenguinPrice:
		#if the current penguin price is 0, and its not because there are no penguins
		#then the player is using a free penguin from their inventory
		if currentPenguinPrice == 0 and penguins.size() > 0: 
			var currData = PlayerData.getData()
			currData["Inventory"][0] = currData["Inventory"][0] - 1
			PlayerData.setData(currData)
			PlayerData.saveData() 
		spendGems(currentPenguinPrice)
		print("Penguin added at: " + str(globalPosition.x) + " && " + str(globalPosition.y))
		addPenguinAtLocation(globalPosition)
		$Camera/PurchaseSound.play()
		givePlayerExperience(100, globalPosition)
		var currentPenguinAmount = penguins.size()
		#if there is significant load on the system at the time of purchase, the achievement unlock might not go through
		#by using if's instead of match, we can guarantee that the player will unlock the previous achievement at least during
		#their next penguin purchase to avoid the situation where an achievement is unobtainable without restarting progress or killing penguins
		if currentPenguinAmount >= 2: 
			#Penguin Hobbyist achievement
			$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQDw")
		if currentPenguinAmount >= 5: 
			#Penguin entrepreneur achievement
			$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQEA")
		if currentPenguinAmount >= 10: 
			#Penguin master achievement
			$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQEQ")
		if currentPenguinAmount >= 20: 
			#Penguin whisperer achievement
			$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQDg")
		#Biggest Penguin Population leaderboard score submit
		$LeaderboardsClient.submit_score("CgkI8tzE1rMcEAIQAw", currentPenguinAmount)
		updatePenguinAndFoodSavedArray()
		calculateCurrentPenguinPrice()
	isDragging = false
	
func existingBowlDropped(_atPosition: Vector2, data):
	print("an existing bowl has been dropped and received")
	var bowlPosition = $Camera.get_global_mouse_position()
	data.setLocation(bowlPosition.x, bowlPosition.y)
	data.get_child(0).get_child(1).visible = true
	updatePenguinAndFoodSavedArray()
	isDragging = false

func newBowlIsDropped(_atPosition: Vector2): 
	print("a new food bowl has been dropped and recevied")
	var bowlPosition = $Camera.get_global_mouse_position()
	if PlayerData.getData()["Gems"] >= 100:
		spendGems(100)
		var food: Food = food_scene.instantiate()
		food.setLocation(bowlPosition.x, bowlPosition.y)
		food.addFood(100)
		foodBowls.push_back(food)
		add_child(food)
		var currData = PlayerData.getData()
		var currFood = currData["Food"]
		currFood.push_back({"amount": 100, "locationX": bowlPosition.x, "locationY": bowlPosition.y})
		currData["Food"] = currFood
		print(currData)
		PlayerData.setData(currData)
		PlayerData.saveData()
	isDragging = false

func medicineIsDropped(_atPosition: Vector2): 
	print("medicine has been dropped and received")
	#find the closest sick penguin
	#heal the penguin + play animation
	#update the players cloud data
	var medicineDropPosition = $Camera.get_global_mouse_position()
	var closestPenguin
	var closestDistance = 99999999
	for penguin in penguins: 
		if penguin.getSick():
			var distanceFromThisPenguin = medicineDropPosition.distance_squared_to(penguin.global_position)
			if distanceFromThisPenguin < closestDistance: 
				closestDistance = distanceFromThisPenguin
				closestPenguin = penguin
	if closestPenguin: 
		print("we found the closest sick penguin, checking gem amount available")
		if PlayerData.getData()["Gems"] >= currentMedicinePrice: 
			print("we found the closest sick penguin, clearing status")
			if not isTutorialCompleted and int(tutorialProgress) == 5:
				updateTutorialProgress(6)
				checkTutorialProgress()
			closestPenguin.setSick(false)
			closestPenguin.addFood(25)
			$Camera/PurchaseSound.play()
			givePlayerExperience(25, closestPenguin.global_position)
			#Penguin Doctor achievement
			$AchievementsClient.unlock_achievement("CgkI8tzE1rMcEAIQCA")
			spendGems(currentMedicinePrice)
			#if the currentMedicinePrice is 0, the player is using a medicine from their inventory
			if currentMedicinePrice == 0:
				var currData = PlayerData.getData()
				currData["Inventory"][2] = currData["Inventory"][2] - 1
				PlayerData.setData(currData)
				PlayerData.saveData()
			calculateCurrentPenguinPrice() 
			updatePenguinAndFoodSavedArray()
	else: 
		print("there was no sick penguin, or there was an error")
	isDragging = false
	
func foodIsDropped(atPosition: Vector2): 
	print("food has been dropped and received")
	#feed all penguins + play animation
	if PlayerData.getData()["Gems"] >= currentFoodPrice:
		#if the current food price is 0, the player is using a free food bag from their inventory
		if currentFoodPrice == 0:
			var currData = PlayerData.getData()
			currData["Inventory"][1] = currData["Inventory"][1] - 1
			PlayerData.setData(currData)
			PlayerData.saveData() 
		$Camera/PurchaseSound.play() 
		for penguin in penguins: 
			penguin.setFood(100)
		for bowl in foodBowls: 
			bowl.addFood(100)
		updatePenguinAndFoodSavedArray()
		spendGems(currentFoodPrice)
		givePlayerExperience(25, atPosition)
		calculateCurrentPenguinPrice()
	isDragging = false
	
func dragToggle(): 
	print("there is an item being dragged from the sidebar")
	isDragging = true
	
func setDragToggle(isDrag): 
	isDragging = isDrag

#var pressing = false
#var pressStartTime = 0.0
#var pressPos = Vector2.ZERO
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		print("location clicked")
		print("InputEventMouseButton")
		for p in penguins: 
			if p.selected: 
				print("controlling penguin")
				if not isTutorialCompleted and int(tutorialProgress) == 0:
					updateTutorialProgress(1)
					checkTutorialProgress()
				#var globalPosition = to_global(event.position)
				var globalPosition = $Camera.get_global_mouse_position()
				print("InputEvent -> x: " + str(globalPosition.x) + " y: " + str(globalPosition.y))
				p.setGoal(globalPosition.x, globalPosition.y)
				p.stopTime()
				p.setSelected(false)
				if p.current_area == "Water": 
					p.setState("Swim")
				else:
					#a penguin walking on the ice mountain is given a new target below itself -> should slide down mountain
					if p.current_state == "Walk" and globalPosition.y > p.position.y and doesIceMountainHaveThisPenguin(p): 
						p.setState("Slide") 
					#a penguin sliding down the mountain, is given a new target below itself -> should keep sliding
					elif p.current_state == "StillSliding" and globalPosition.y > p.position.y: 
						pass
					#otherwise the penguin should be walking
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
	if fishes.size() < 25: 
		$FishSpawnTimer.wait_time = randf_range(8,15)
		var fish: Fish = fish_scene.instantiate()
		var randomTypeValue = randf_range(0,100)
		if(randomTypeValue < 90): 
			fish.setType("blue")
		elif (randomTypeValue > 90 and randomTypeValue < 97): 
			fish.setType("purple")
		else: 
			fish.setType("gold")
		var randomSpawnLocation = get_random_point_in_collision_polygon($WaterArea/WaterCollision)
		var randomYDifferential = randf_range(200,350)
		fish.setLocation(randomSpawnLocation.x, randomSpawnLocation.y+randomYDifferential)
		fish.fish_collected.connect(onFishCollected)
		fish.fish_needs_target.connect(onGiveFishGoal)
		fish.fish_idle_needs_new_goal.connect(onGiveFishGoal)
		fish.fish_danger_check.connect(onFishDanger)
		add_child(fish)
		onGiveFishGoal(fish)
		fishes.push_back(fish)
	else: 
		print("there are already 25 fish in the pond, skipping")
	
func _on_gem_spawn_timer_timeout() -> void:
	print("gem spawn timeout")
	$GemSpawnTimer.wait_time = randf_range(10,20)
	var gem = gem_scene.instantiate()
	var randomSpawn = get_random_point_in_collision_polygon($IceMountainArea/IceMountainCollision)
	gem.global_position = randomSpawn
	gem.gem_collected.connect(onGemCollected)
	add_child(gem)
	gems.push_back(gem)
	
func get_random_point_in_collision_polygon(collision_polygon: CollisionPolygon2D) -> Vector2:
	var poly: PackedVector2Array = collision_polygon.polygon
	if poly.size() < 3:
		return collision_polygon.global_position

	var tri_idx: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if tri_idx.is_empty():
		return collision_polygon.global_position

	# --- Build cumulative area table (for weighted triangle selection) ---
	var cumulative := PackedFloat32Array()
	cumulative.resize(tri_idx.size() / 3)
	var total_area := 0.0

	var ci := 0
	for i in range(0, tri_idx.size(), 3):
		var a: Vector2 = poly[tri_idx[i]]
		var b: Vector2 = poly[tri_idx[i + 1]]
		var c: Vector2 = poly[tri_idx[i + 2]]
		var area: float = abs((b - a).cross(c - a)) * 0.5  # triangle area
		total_area += area
		cumulative[ci] = total_area
		ci += 1

	if total_area <= 0.0:
		return collision_polygon.global_position

	# --- Pick a triangle proportional to its area ---
	var r := randf() * total_area
	var t_index := 0
	while t_index < cumulative.size() and r > cumulative[t_index]:
		t_index += 1
	var base := t_index * 3

	var A: Vector2 = poly[tri_idx[base]]
	var B: Vector2 = poly[tri_idx[base + 1]]
	var C: Vector2 = poly[tri_idx[base + 2]]

	# --- Uniform random point in triangle ABC using barycentric coordinates ---
	# Use the sqrt trick so density is uniform over area.
	var r1 := randf()
	var r2 := randf()
	var sqrt_r1 := sqrt(r1)
	var u := 1.0 - sqrt_r1
	var v := r2 * sqrt_r1
	var w := 1.0 - u - v

	var p_local: Vector2 = A * u + B * v + C * w
	return collision_polygon.to_global(p_local)  # if you want a global/world-space point
	
func is_point_inside_polygon(collision_polygon: CollisionPolygon2D, point: Vector2) -> bool:
	var local_point = collision_polygon.get_global_transform().affine_inverse() * point
	return Geometry2D.is_point_in_polygon(local_point, collision_polygon.polygon)

func calculateCurrentPenguinPrice() -> void: 
	var currentPenguins = penguins.size()
	print("there are currently " + str(currentPenguins) + " in the enclosure")
	#base cost
	var base = 50
	#scale factor
	var scal = 22
	#rate of growth
	var p = 1.75
	var calculatedExactCost = base + scal * pow(float(currentPenguins - 1), p)
	var roundedCost = int(round(calculatedExactCost / 5.0) * 5.0)
	var currData = PlayerData.getData()
	print(roundedCost)
	var noPenguins = false
	if currentPenguins == 0 or currData["Inventory"][0] > 0: 
		currentPenguinPrice = 0
		sidebarHandle.setCurrentPenguinInventory(currData["Inventory"][0])
		if currData["Inventory"][0] == 0: 
			sidebarHandle.setCurrentPenguinInventory(0)
			noPenguins = true
	else: 
		currentPenguinPrice = roundedCost
		sidebarHandle.setCurrentPenguinInventory(0)
	sidebarHandle.setCurrentPenguinCost(currentPenguinPrice, noPenguins)
	#if the player has free food bags in their inventory
	if currData["Inventory"][1] > 0: 
		sidebarHandle.setCurrentFoodCost(0)
		sidebarHandle.setCurrentFoodInventory(currData["Inventory"][1])
		currentFoodPrice = 0
	else: 
		currentFoodPrice = 100
		sidebarHandle.setCurrentFoodCost(100)
		sidebarHandle.setCurrentFoodInventory(0)
	#if the player has free medicine in their inventory
	if currData["Inventory"][2] > 0: 
		sidebarHandle.setCurrentMedicineCost(0)
		sidebarHandle.setCurrentMedicineInventory(currData["Inventory"][2])
		currentMedicinePrice = 0
	else: 
		currentMedicinePrice = 75
		sidebarHandle.setCurrentMedicineCost(75)
		sidebarHandle.setCurrentMedicineInventory(0)

func _on_side_bar_pressed() -> void:
	print("side bar pressed")
	if not isTutorialCompleted and int(tutorialProgress) == 4: 
		tutDialog.setDialogText("Good! Now drag and drop the penguin icon somewhere on the iceberg!")
	if not sidebarActive:
		var currData = PlayerData.getData()
		sidebarHandle.setCurrentPenguinInventory(currData["Inventory"][0])
		sidebarHandle.setCurrentFoodInventory(currData["Inventory"][1])
		sidebarHandle.setCurrentMedicineInventory(currData["Inventory"][2])
		$CanvasMenu.add_child(sidebarHandle)
		sidebarActive = true
	else: 
		$CanvasMenu.remove_child(sidebarHandle)
		sidebarActive = false

func _on_main_music_finished() -> void:
	$Camera/MainMusic.play()

func _on_main_music_evening_finished() -> void:
	$Camera/MainMusic_Evening.play()
	
func _on_loading_bar_child_entered_tree(_node: Node) -> void:
	$LoadingBar/LoadingPenguin.play()

func _on_air_area_area_entered(area: Area2D) -> void:
	print("there is a penguin in the air area, forcing a slide")
	if area is Penguin: 
		area.setState("Slide")
		onGivePenguinGoal(area)
