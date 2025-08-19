extends Node2D

var currentData = ""
@onready var snapshotsClient: PlayGamesSnapshotsClient = PlayGamesSnapshotsClient.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func setData(data):
	currentData = data
	
func getData(): 
	return currentData
