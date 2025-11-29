extends Sprite2D

signal rewardAccepted

var gemsGained = 0
var foodGained = 0
var penguinsGained = 0
var medicineGained = 0

var currentDay = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setCurrentDay(day) -> void:
	print("setting the current daily prize to the day " + str(day)) 
	currentDay = day
	match currentDay: 
		1: 
			$Day1Label/CurrentHighlight.visible = true
		2: 
			$Day2Label/CurrentHighlight.visible = true
		3: 
			$Day3Label/CurrentHighlight.visible = true
		4: 
			$Day4Label/CurrentHighlight.visible = true
		5: 
			$Day5Label/CurrentHighlight.visible = true
		6: 
			$Day6Label/CurrentHighlight.visible = true
		7: 
			$Day7Label/CurrentHighlight.visible = true

func _on_accept_prize_pressed() -> void:
	print("daily reward prize accepted")
	match currentDay: 
		1: 
			gemsGained = 50
			penguinsGained = 0
			foodGained = 1
			medicineGained = 0
		2: 
			gemsGained = 100
			penguinsGained = 0
			foodGained = 1
			medicineGained = 0
		3: 
			gemsGained = 150
			penguinsGained = 0
			foodGained = 0
			medicineGained = 1
		4: 
			gemsGained = 100
			penguinsGained = 1
			foodGained = 0
			medicineGained = 0
		5: 
			gemsGained = 200
			penguinsGained = 0
			foodGained = 2
			medicineGained = 0
		6: 
			gemsGained = 100
			penguinsGained = 1
			foodGained = 1
			medicineGained = 0
		7: 
			gemsGained = 300
			penguinsGained = 1
			foodGained = 0
			medicineGained = 0
	rewardAccepted.emit(gemsGained, penguinsGained, foodGained, medicineGained)
	queue_free()
	
