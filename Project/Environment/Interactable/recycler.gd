extends Node3D

@export var recycler_storage: Node3D
@export var recycler_button: MeshInstance3D
@export var replicator_button: MeshInstance3D

var label_name := "\nRecycler/Replicator\n\nPlace things on top then \nhit red button to recycle.\n\nHit green button to replicate."

var objects_to_recycle = []

func _ready() -> void:
	Signalmanager.recycle.connect(recycle)

func store_mats(obj):
	recycler_storage.add_child(obj)
	objects_to_recycle.append(obj)
	
	
func recycle():
	for obj in objects_to_recycle:
		if obj.ingredient_name:
			var obj_name = obj.ingredient_name
			print (obj_name)
			print (Resourcemanager.INGREDIENTS[obj_name]["print_mats"]["Matter"])
			var res_mats = int(ceil(Resourcemanager.INGREDIENTS[obj_name]["print_mats"]["Matter"] / 2.0))
			Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"] += res_mats
		if obj.has_method("despawn"):
			obj.despawn()
		else:
			obj.queue_free()
		Signalmanager.update_res_display.emit()
	objects_to_recycle.clear()
