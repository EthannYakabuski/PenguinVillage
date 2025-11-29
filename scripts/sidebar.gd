extends Control

signal isDraggingSignal

var currentPenguinCost = 50
var currentMedicineCost = 75
var currentFoodCost = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func setCurrentPenguinCost(amount): 
	currentPenguinCost = amount
	$PenguinGemLabel.text = str(amount)
	
func setCurrentMedicineCost(amount): 
	currentMedicineCost = amount
	$MedicineGemLabel.text = str(amount)

func setCurrentFoodCost(amount): 
	currentFoodCost = amount
	$FoodGemLabel.text = str(amount)

func _on_purchase_control_is_dragging(_item: Control) -> void:
	print("a purchase is being dragged")
	isDraggingSignal.emit()
