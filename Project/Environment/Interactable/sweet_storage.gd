extends Node3D

var label_name : String
@export var max_storage: float = 500

func _ready() -> void:
	Signalmanager.update_ressource_label.connect(update_ressource_label)
	label_name = "Sweet Molecules " + str(Gamemanager.REPLICATOR_RESSOURCES.get("Sweet_Molecules").get("current_amount")) +" von " + str(max_storage)


func update_ressource_label():
	label_name = "Sweet Molecules " + str(Gamemanager.REPLICATOR_RESSOURCES.get("Sweet_Molecules").get("current_amount")) +" von " + str(max_storage)
