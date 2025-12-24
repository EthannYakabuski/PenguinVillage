extends Sprite2D

var pressedAmount = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setDialogText(content) -> void: 
	print("setting dialog text")
	$DialogText.text = content
	
func moveYAxisDown() -> void: 
	position.y = position.y + 1200
	
func moveYAxisUp() -> void: 
	position.y = position.y - 1200
	
func makeButtonVisible() -> void: 
	$AcceptButton.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_accept_button_pressed() -> void:
	if pressedAmount == 0: 
		$DialogText.text = "The object of the game is to see how many penguins you can collect!"
	elif pressedAmount == 1: 
		$DialogText.text = "If you let a penguin be sick for too long, it may pass away"
	elif pressedAmount == 2: 
		$DialogText.text = "Don't forget to come back everyday to feed them, and collect your daily rewards. See ya later!"
	else: 
		self.visible = false
	pressedAmount = pressedAmount + 1
