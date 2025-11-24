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
	prizeAccepted.emit()
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
		if randomPrize in range(1,50): 
			print("prize is a free food bag")
			foodGained = 1
			$FoodBag.visible = true
		elif randomPrize in range(51,75): 
			print("prize is a free medicine")
			medicineGained = 1
			$Medicine.visible = true
		elif randomPrize in range(76,100): 
			print("prize is a free penguin")
			penguinsGained = 1
			$PenguinPrize.visible = true
	else: 
		print("showing two prizes to claim")
		$Gems.position.x = $Gems.position.x - 100
		if randomPrize in range(1,30): 
			print("prize is two food bags")
			var foodBagClone = $FoodBag.duplicate()
			foodBagClone.position.x = foodBagClone.position.x - 100
			foodBagClone.visible = true
			add_child(foodBagClone)
			$FoodBag.position.x = $FoodBag.position.x + 100
			$FoodBag.visible = true
		elif randomPrize in range(31,50): 
			print("prize is a food bag and a medicine")
			$FoodBag.position.x = $FoodBag.position.x - 100
			$Medicine.position.x = $Medicine.position.x + 100
			$FoodBag.visible = true
			$Medicine.visible = true
		elif randomPrize in range(51,75): 
			print("prize is two medicine")
			var medicineClone = $Medicine.duplicate()
			medicineClone.position.x = medicineClone.position.x - 100
			medicineClone.visible = true
			add_child(medicineClone)
			$Medicine.position.x = $Medicine.position.x + 100
			$Medicine.visible = true
		elif randomPrize in range(76,85): 
			print("prize is a food bag and a penguin")
			$FoodBag.position.x = $FoodBag.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			$FoodBag.visible = true
			$PenguinPrize.visible = true
		elif randomPrize in range(86,95): 
			print("prize is a medicine and a penguin")
			$Medicine.position.x = $Medicine.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			$Medicine.visible = true
			$PenguinPrize.visible = true
		elif randomPrize in range(96,100): 
			print("prize is two free penguins")
			var penguinClone = $PenguinPrize.duplicate()
			penguinClone.position.x = penguinClone.position.x - 100
			$PenguinPrize.position.x = $PenguinPrize.position.x + 100
			penguinClone.visible = true
			add_child(penguinClone)
			$PenguinPrize.visible = true
