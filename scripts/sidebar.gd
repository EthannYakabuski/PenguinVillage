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

func setCurrentPenguinCost(amount, noPenguins): 
	currentPenguinCost = amount
	$PenguinGemLabel.text = str(int(amount))
	if amount == 0: 
		$PenguinGemIndicator.visible = false
		$PenguinGemLabel.visible = false
	else: 
		$PenguinGemIndicator.visible = true
		$PenguinGemLabel.visible = true
	if noPenguins: 
		$PenguinGemIndicator.visible = true
		$PenguinGemLabel.visible = true
		$PenguinGemLabel.text = "Free"
	
func setCurrentMedicineCost(amount): 
	currentMedicineCost = amount
	$MedicineGemLabel.text = str(int(amount))
	if amount == 0: 
		$MedicineIndicator.visible = false
		$MedicineGemLabel.visible = false
	else: 
		$MedicineIndicator.visible = true
		$MedicineGemLabel.visible = true

func setCurrentFoodCost(amount): 
	currentFoodCost = amount
	$FoodGemLabel.text = str(int(amount))
	if amount == 0: 
		$FoodGemIndicator.visible = false
		$FoodGemLabel.visible = false
	else: 
		$FoodGemIndicator.visible = true
		$FoodGemLabel.visible = true
	
func setCurrentFoodInventory(amount): 
	$FoodInventoryLabel.text = str(int(amount))
	
func setCurrentMedicineInventory(amount): 
	$MedicineInventoryLabel.text = str(int(amount))
	
func setCurrentPenguinInventory(amount): 
	$PenguinInventoryLabel.text = str(int(amount))

func _on_purchase_control_is_dragging(_item: Control) -> void:
	print("a purchase is being dragged")
	isDraggingSignal.emit()

func _on_achievements_button_pressed() -> void:
	print("loading achievements")
	get_parent().get_parent().loadAchievements()

func _on_leaderboards_button_pressed() -> void:
	print("loading leaderboards")
	get_parent().get_parent().loadLeaderboards()
