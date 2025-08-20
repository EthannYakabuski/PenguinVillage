extends Node2D

var currentData = ""
@onready var snapshotsClient: PlayGamesSnapshotsClient = PlayGamesSnapshotsClient.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	snapshotsClient.game_saved.connect(
		func(is_saved: bool, save_data_name: String, save_data_description: String): 
			print("data saved " + str(is_saved))
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setData(data):
	currentData = data
	
func getData(): 
	return currentData
	
func saveData(): 
	var dataToSave = JSON.stringify(currentData)
	snapshotsClient.save_game("PlayerData", "player data for Penguin Village", dataToSave.to_utf8_buffer())
