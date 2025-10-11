extends Control

var replicator_markers: Array[Marker3D] = []

func _ready() -> void:
	Gamemanager.is_in_menu = true
	Gamemanager.main_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Signalmanager.toggle_all_ui_for_replicator.emit(false)
	for n in get_tree().get_nodes_in_group("replicator_slot"):
		if n is Marker3D:
			replicator_markers.append(n)
	print("Replicator Slots: ", replicator_markers.size())
	
	
func _on_rum_btn_pressed() -> void:
	_on_drink_btn_pressed("Rum")
	_on_back_btn_pressed()


func _on_whiskey_btn_pressed() -> void:
	_on_drink_btn_pressed("Whisky")
	_on_back_btn_pressed()


func _on_wodka_btn_pressed() -> void:
	_on_drink_btn_pressed("Wodka")
	_on_back_btn_pressed()


func _on_beer_btn_pressed() -> void:	
	_on_drink_btn_pressed("Beer")
	_on_back_btn_pressed()
	
	
func _on_glass_btn_pressed() -> void:
	_on_drink_btn_pressed("Glass")
	_on_back_btn_pressed()

func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel") and Gamemanager.is_in_menu:
		_on_back_btn_pressed()
		
		
func _on_back_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Gamemanager.replicator_open = false
	Gamemanager.main_ui.visible = true
	Signalmanager.update_res_display.emit()
	self.queue_free()
	
	
func _can_afford(drink_name: String) -> bool:
	var mats = Resourcemanager.INGREDIENTS[drink_name]["print_mats"]
	for mat_name in mats.keys():
		if Resourcemanager.REPLICATOR_RESSOURCES[mat_name]["current_amount"] < mats[mat_name]:
			return false
	return true
	
	
func _on_drink_btn_pressed(drink_name: String) -> void:
	print("Drink: ", drink_name)
	if not _can_afford(drink_name):
		print("Nicht genug Material für", drink_name)
		return
		
	var mats = Resourcemanager.INGREDIENTS[drink_name]["print_mats"]
	for mat_name in mats.keys():
		print ("Mat: ", mat_name, mats[mat_name])
		Resourcemanager.REPLICATOR_RESSOURCES[mat_name]["current_amount"] -= mats[mat_name]
	
	var slot = Gamemanager.get_free_marker(replicator_markers)
	if slot:    
		var obj = Resourcemanager.INGREDIENTS[drink_name]["res"].instantiate()
		slot.add_child(obj)
		
	#replicator_marker.add_child(obj)
	Signalmanager.update_ressource_label.emit()
	_on_back_btn_pressed()

	
#func set_replicator_marker(marker1: Marker3D,marker2: Marker3D,marker3: Marker3D,
#marker4: Marker3D,marker5: Marker3D, marker6: Marker3D, marker7: Marker3D):
	#replicator_marker1 = marker1
	#replicator_marker2 = marker2
	#replicator_marker3 = marker3
	#replicator_marker4 = marker4
	#replicator_marker5 = marker5
	#replicator_marker6 = marker6
	#replicator_marker7 = marker7
