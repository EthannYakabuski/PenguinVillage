extends Node2D

var currentData = ""
@onready var snapshotsClient: PlayGamesSnapshotsClient = PlayGamesSnapshotsClient.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	snapshotsClient.game_saved.connect(
		func(is_saved: bool, _save_data_name: String, _save_data_description: String): 
			print("data saved " + str(is_saved))
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func setData(data):
	currentData = data
	
func getData(): 
	return currentData
	
func saveData(context = null):
	print("saving data")
	if context == null: 
		print("saving data without context set") 
		var dataToSave = JSON.stringify(currentData)
		snapshotsClient.save_game("PenguinVillageData", "player data for Penguin Village", dataToSave.to_utf8_buffer())
	else: 
		print("saving data with context")
		var dataToSave = JSON.stringify(currentData)
		snapshotsClient.save_game("PenguinVillageData", "player data for Penguin Village", dataToSave.to_utf8_buffer())
		snapshotsClient.game_saved.connect(
			func(_is_saved: bool, _save_data_name: String, _save_data_description: String): 
				print("saved data callback completed")
				context.emit_signal("dataHasLoaded")
		)
