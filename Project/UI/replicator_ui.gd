#replicator_ui.gd
extends Control

var replicator_markers: Array[Marker3D] = []
const USE_COINS := false

func _ready() -> void:
	Gamemanager.is_in_menu = true
	Gamemanager.main_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Signalmanager.toggle_all_ui_for_replicator.emit(false)

	replicator_markers.clear()
	for n in get_tree().get_nodes_in_group("replicator_slot"):
		if n is Marker3D:
			replicator_markers.append(n)
	print("Replicator Slots:", replicator_markers.size())

# --- kleine Helper-Funktion: freien Slot finden ---
func _find_free_replicator_slot() -> Marker3D:
	for m in replicator_markers:
		if is_instance_valid(m) and m.get_child_count() == 0:
			return m
	return null

# Buttons…
func _on_rum_btn_pressed() -> void:
	_on_drink_btn_pressed("Rum"); _on_back_btn_pressed()
func _on_whiskey_btn_pressed() -> void:
	_on_drink_btn_pressed("Whisky"); _on_back_btn_pressed()
func _on_wodka_btn_pressed() -> void:
	_on_drink_btn_pressed("Wodka"); _on_back_btn_pressed()
func _on_beer_btn_pressed() -> void:
	_on_drink_btn_pressed("Beer"); _on_back_btn_pressed()
func _on_glass_btn_pressed() -> void:
	_on_drink_btn_pressed("Glass"); _on_back_btn_pressed()

func _process(_dt: float) -> void:
	if Input.is_action_pressed("ui_cancel") and Gamemanager.is_in_menu:
		_on_back_btn_pressed()

func _on_back_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Gamemanager.replicator_open = false
	Gamemanager.main_ui.visible = true
	Signalmanager.update_res_display.emit()
	queue_free()

func _can_afford(item_id: String) -> bool:
	return ReplicatorDB.can_afford(item_id)

func _on_drink_btn_pressed(item_id: String) -> void:
	print("Replicate:", item_id)

	var item: ReplicatorItem = ReplicatorDB.get_item(item_id)
	print("[R] item:", item, " scene:", item and item.scene, " isPacked=", item and item.scene is PackedScene,
	  " path=", item and item.scene and item.scene.resource_path)
	if item == null:
		Signalmanager.update_info_text_label.emit("Unbekanntes Item."); return
	if not ReplicatorDB.can_afford(item_id):
		Signalmanager.update_info_text_label.emit("Nicht genug Materialien."); return

	# HIER: lokalen Finder benutzen statt Gamemanager.get_free_marker(...)
	var slot: Marker3D = _find_free_replicator_slot()
	if slot == null:
		Signalmanager.update_info_text_label.emit("Kein freier Slot."); return

	ReplicatorDB.consume_cost(item_id)
	Signalmanager.update_res_display.emit()
	Signalmanager.update_ressource_label.emit()

	if item.scene:
		var obj: Node3D = item.scene.instantiate()
		obj.set_meta("replicator_item_id", item.id)

		if obj.is_in_group("Bottle"):
			if item.default_liquid: obj.set("liquid", item.default_liquid)
			if item.default_ml > 0 and obj.has_method("set_liquid"):
				obj.set_liquid(float(item.default_ml))
		elif obj.is_in_group("BeerBottle"):
			if item.default_liquid: obj.set("liquid", item.default_liquid)
			if item.default_ml > 0:
				obj.set("volume_ml", int(item.default_ml))

		slot.add_child(obj)
	else:
		Signalmanager.update_info_text_label.emit("Item hat keine Szene.")
