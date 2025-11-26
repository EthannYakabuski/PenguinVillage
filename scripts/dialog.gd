extends Sprite2D

signal prizeAccepted

var gemsGained = 0
var foodGained = 0
var penguinsGained = 0
var medicineGained = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setDisplayedLevel(level, doubleLevel) -> void: 
	$LevelIndicator/LevelLabel.text = str(level)
	setDisplayedPrize(level, doubleLevel)

func _on_accept_prize_pressed() -> void:
	print("accepting level up prize")
	prizeAccepted.emit(gemsGained, penguinsGained, foodGained, medicineGained)
	queue_free()
	
func setDisplayedPrize(level, doubleLevel) -> void: 
	print("setting displayed prize")
	gemsGained = level*10
	if doubleLevel: 
		gemsGained = gemsGained + 10*(level-1)
	$Gems/GemAmountLabel.text = str(gemsGained)
	$Gems.visible = true
	var randomPrize = randi_range(1,100)
	if not doubleLevel:
		randomPrize = 50
		if randomPrize in range(1,51): 
			print("prize is a free food bag")
			foodGained = 1
			$FoodBag.visible = true
		elif randomPrize in range(51,76): 
			print("prize is a free medicine")
			medicineGained = 1
			$Medicine.visible = true
		elif randomPrize in range(76,101): 
			print("prize is a free penguin")
			penguinsGained = 1
			$PenguinPrize.visible = true
	else: 
		print("showing two prizes to claim")
		$Gems.position.x = $Gems.position.x - 100
		if randomPrize in range(1,31): 
			print("prize is two food bags")
			foodGained = 2
			var foodBagClone = $FoodBag.duplicate()
			foodBagClone.position.x = foodBagClone.position.x - 100
			foodBagClone.visible = true
			add_child(foodBagClone)
			$FoodBag.position.x = $FoodBag.position.x + 100
			$FoodBag.visible = true
		elif randomPrize in range(31,51): 
			print("prize is a food bag and a medicine")
			foodGained = 1
			medicineGained = 1
			$FoodBag.position.x = $FoodBag.position.x - 100
			$Medicine.position.x = $Medicine.position.x + 100
			$FoodBag.visible = true
			$Medicine.visible = true
		elif randomPrize in range(51,76): 
			print("prize is two medicine")
			medicineGained = 2
			var medicineClone = $Medicine.duplicate()
			medicineClone.position.x = medicineClone.position.x - 100
			medicineClone.visible = true
			add_child(medicineClone)
			$Medicine.position.x = $Medicine.position.x + 100
			$Medicine.visible = true
		elif randomPrize in range(76,88): 
			print("prize is a food bag and a penguin")
			foodGained = 1
			penguinsGained = 1
			$FoodBag.position.x = $FoodBag.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			$FoodBag.visible = true
			$PenguinPrize.visible = true
		elif randomPrize in range(86,96): 
			print("prize is a medicine and a penguin")
			medicineGained = 1
			penguinsGained = 1
			$Medicine.position.x = $Medicine.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			$Medicine.visible = true
			$PenguinPrize.visible = true
		elif randomPrize in range(96,101): 
			print("prize is two free penguins")
			penguinsGained = 2
			var penguinClone = $PenguinPrize.duplicate()
			penguinClone.position.x = penguinClone.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			penguinClone.visible = true
			add_child(penguinClone)
			$PenguinPrize.visible = true
