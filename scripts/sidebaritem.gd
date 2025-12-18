extends Control

@export var controlItemType: String
signal isDragging
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func foodBowlHeld(bowl) -> void: 
	get_parent().foodBowlHeld(bowl)
	
func setControlItemType(type) -> void:
	print("setting controlItemType to " + type) 
	self.controlItemType = type

func _get_drag_data(_Vector2):
	print("get drag data is being called")
	var preview = TextureRect.new()
	var scaleX
	var scaleY
	var texSize
	if controlItemType == "Penguin":
		preview.texture = $PenguinPurchase.texture
		texSize = $PenguinPurchase.size
		scaleX = $PenguinPurchase.scale.x
		scaleY = $PenguinPurchase.scale.y
	elif controlItemType == "Food": 
		preview.texture = $FoodBagPurchase.texture
		texSize = $FoodBagPurchase.size
		scaleX = $FoodBagPurchase.scale.x - 0.10
		scaleY = $FoodBagPurchase.scale.y - 0.10
	elif controlItemType == "Medicine": 
		preview.texture = $MedicinePurchase.texture 
		texSize = $MedicinePurchase.size
		scaleX = $MedicinePurchase.scale.x - 0.10
		scaleY = $MedicinePurchase.scale.y - 0.10
	elif controlItemType == "FoodBowl":
		preview.texture = $FoodBowlPurchase.texture 
		texSize = $FoodBowlPurchase.size
		scaleX = $FoodBowlPurchase.scale.x - 0.10
		scaleY = $FoodBowlPurchase.scale.y - 0.10
	preview.size = texSize
	preview.scale.x = scaleX
	preview.scale.y = scaleY
	set_drag_preview(preview)
	isDragging.emit(self)
	return self
