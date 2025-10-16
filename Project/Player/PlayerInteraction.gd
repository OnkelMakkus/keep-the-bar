# PlayerInteraction.gd
extends Node

@export var player: CharacterBody3D
@export var head: Node3D
@export var camera: Camera3D
@export var hand_slot: Node3D
@export var aim: PlayerAim

var held_object: Node3D = null
var is_pouring: bool = false
var hand_pos: Vector3 = Vector3.ZERO
var pour_rate_ml: float = 40.0
var prepare_for_recycling: bool = false
var last_label_owner: Node = null


func _ready() -> void:
	hand_pos = hand_slot.position
	Signalmanager.give_player_stuff.connect(_give_player_stuff)
	Signalmanager.change_fov.connect(_apply_fov)
	Signalmanager.change_fov.emit()


func _input(event: InputEvent) -> void:
	if Gamemanager.is_in_menu:
		return

	if event.is_action_pressed("primary_interact"):
		_on_primary()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_start_pour_animation()
		else:
			_reset_pour_animation()
		return

	if event.is_action_pressed("use_context"):
		_on_use_context()
		return

	if event.is_action_pressed("drop"):
		_on_drop_key()
		return


func _physics_process(delta: float) -> void:
	_show_bottle_label()
	if is_pouring and held_object and held_object.is_in_group("Bottle"):
		_process_pouring(delta)


# ---------- Public (für Player-Fassade) ----------
func pick_up(item: Node3D) -> void:
	held_object = item
	_place_handslot_z()
	Gamemanager.freeze_for_pickup(held_object) 
	hand_slot.add_child(held_object)
	held_object.transform = Transform3D.IDENTITY
	held_object.rotation = Vector3.ZERO


# ---------- Primär ----------
func _on_primary() -> void:
	if held_object:
		_place_or_free()
	else:
		_try_interact_or_pickup()


func _try_interact_or_pickup() -> void:	
	var hit_obj: Object = aim.collider()
	if hit_obj == null:
		return
	var hit := hit_obj as Node

	# Einmal Owner holen
	var grp_owner := Gamemanager.find_owner_in_any_group(hit, ["Open_Schild","Order_Schild","Recycler_Button","Replicator","Customer"])
	# Optional: Kurzdebug
	print("owner=", grp_owner, " groups=", grp_owner.get_groups() if grp_owner else [])

	if grp_owner:
		if grp_owner.is_in_group("Open_Schild"):
			Signalmanager.open_shop.emit(); return
		if grp_owner.is_in_group("Order_Schild"):
			Signalmanager.open_order.emit(); return
		if grp_owner.is_in_group("Recycler_Button"):
			Signalmanager.recycle.emit(); return
		if grp_owner.is_in_group("Replicator") and not Gamemanager.replicator_open:
			grp_owner.open_ui(); return
		if grp_owner.is_in_group("Customer") and not held_object and grp_owner.has_method("clicked_by_player"):
			grp_owner.clicked_by_player(); return

	# …sonst Pickup versuchen
	_try_pickup()



func _try_pickup() -> void:
	var hit_obj: Object = aim.collider()
	if hit_obj == null:
		return
	var hit := hit_obj as Node
	var obj := Gamemanager.find_owner_of_group(hit, "Pickupable")
	if obj == null:
	# Debug-Hilfe: zeige, was wir finden würden
		var bottle := Gamemanager.find_owner_of_group(hit, "Bottle")
		var glass  := Gamemanager.find_owner_of_group(hit, "Glass")
		print("No 'Pickupable' owner. bottle=", bottle, " glass=", glass)
		return
		
	# Objekt aufnehmen
	held_object = obj
	_place_handslot_z()

	await get_tree().process_frame
	if held_object.has_meta("on_theke") and held_object.get_meta("on_theke"):
		held_object.set_meta("on_theke", false)

	Gamemanager.freeze_for_pickup(held_object) 
	held_object.get_parent().remove_child(held_object)
	hand_slot.add_child(held_object)
	held_object.transform = Transform3D.IDENTITY
	held_object.rotation = Vector3.ZERO

	if held_object.is_in_group("BeerBottle") and held_object.has_method("set_obj_scale"):
		held_object.set_obj_scale()

	if held_object.has_signal("finished_pouring"):
		if held_object.is_connected("finished_pouring", Callable(self, "_reset_pour_animation")):
			held_object.disconnect("finished_pouring", Callable(self, "_reset_pour_animation"))
		held_object.connect("finished_pouring", Callable(self, "_reset_pour_animation"))


# ---------- Platzieren / Free ----------
func _place_or_free() -> void:
	var hit_obj: Object = aim.collider()
	var hit := hit_obj as Node
	if hit:
		# Recycler
		if hit.has_method("show_besitzer") and hit.show_besitzer().is_in_group("Recycler"):
			var wp := aim.collision_point()
			var n  := Vector3.UP
			if aim.ray_front and aim.ray_front.is_colliding():
				n = aim.ray_front.get_collision_normal()
			hand_slot.remove_child(held_object)
			hit.show_besitzer().store_mats(held_object, wp, n)  # <- Punkt + Normal mitgeben
			prepare_for_recycling = true
			_drop_object()
			return


		var hit_parent := hit.get_parent()

		# Regal-Slots (eigene Platzierlogik)
		if held_object.has_method("place_on_shelf") and hit_parent and hit_parent.is_in_group("Regalbrett"):
			if held_object.place_on_shelf(aim.collision_point(), hit_parent):
				Gamemanager.unfreeze_after_place(held_object)
				_release_held()
				return

		# Kunde (Hand-Over auf Theke)
		if hit.is_in_group("Customer"):
			_move_to_serving_container()
			held_object.global_position = aim.collision_point()
			if held_object.is_in_group("BeerBottle") and held_object.has_method("set_obj_scale"):
				held_object.set_obj_scale()
			if hit.has_method("clicked_by_player"):
				hit.clicked_by_player()
			Gamemanager.unfreeze_after_place(held_object)
			_release_held()
			return

		# Generische, erlaubte Oberflächen: nur placeable_surface
		var surface := Gamemanager.get_placeable_surface_owner(hit)
		if surface:
			# Nicht unter die Fläche parenten → in die Welt hängen
			hand_slot.remove_child(held_object)
			var world_parent: Node = get_tree().current_scene
			world_parent.add_child(held_object)

			# Kollisionspunkt + "Lift" auf die Unterkante des Objekts
			var lift := 0.01
			var base_mesh := held_object.get_node_or_null("Cylinder") as MeshInstance3D
			if base_mesh and base_mesh.mesh:
				var aabb := base_mesh.mesh.get_aabb()
				var h := aabb.size.y * held_object.global_transform.basis.get_scale().y
				lift = max(lift, h * 0.5 - 0.001)

			held_object.global_position = aim.collision_point() + Vector3.UP * lift

			# Spezialfall Theke: Meta setzen
			if surface.is_in_group("Theke"):
				held_object.set_meta("on_theke", true)
				held_object.global_position.y = surface.position_marker.global_position.y

			Gamemanager.unfreeze_after_place(held_object)
			_release_held()
			return

	# Kein erlaubter Untergrund → NICHT platzieren
	Signalmanager.update_info_text_label.emit("Hier kannst du nichts abstellen.")


func _move_to_serving_container() -> void:
	hand_slot.remove_child(held_object)
	Gamemanager.serving_container.add_child(held_object)
	held_object.set_meta("on_theke", true)
	Gamemanager.unfreeze_after_place(held_object)


func _release_held() -> void:
	if is_instance_valid(held_object):
		Gamemanager.unfreeze_after_place(held_object)
	held_object = null
	prepare_for_recycling = false


# ---------- Drop-Key ----------
func _on_drop_key() -> void:
	if not held_object:
		return

	var down := hand_slot.get_node_or_null("RayCast3D_Down") as RayCast3D
	if down and down.is_colliding():
		var hit_pos := down.get_collision_point()
		if held_object.has_method("let_it_fall"):
			held_object.let_it_fall(hit_pos)
		hand_slot.remove_child(held_object)
		player.get_parent().add_child(held_object)
		Gamemanager.unfreeze_after_place(held_object)
		held_object = null
		return

	_drop_object()


func _drop_object() -> void:
	if not held_object:
		return
	if not prepare_for_recycling:
		hand_slot.remove_child(held_object)
		player.get_parent().add_child(held_object)
		Gamemanager.unfreeze_after_place(held_object)
	held_object = null
	prepare_for_recycling = false


# ---------- Pour ----------
func _process_pouring(delta: float) -> void:
	var hit_obj: Object = aim.collider()
	var glass: Node = null
	if hit_obj:
		var target := hit_obj as Node
		glass = Gamemanager.find_owner_of_group(target, "Glass")
	if glass and glass.is_in_group("Glass") and _is_on_theke(glass as Node3D):
		held_object.try_pour_into(glass, pour_rate_ml * delta)
	else:
		_reset_pour_animation()


func _start_pour_animation() -> void:
	camera.fov = Gamemanager.FOV
	hand_pos = hand_slot.position
	hand_slot.position += Vector3(0.1, 0.2, -0.4)
	is_pouring = true
	if held_object and held_object.has_method("start_pouring"):
		held_object.start_pouring()


func _reset_pour_animation() -> void:
	camera.fov = Gamemanager.FOV
	hand_slot.position = hand_pos
	is_pouring = false
	if held_object and held_object.has_method("stop_pouring"):
		held_object.stop_pouring()


# ---------- UI/Label ----------
func _show_bottle_label() -> void:
	var hit_obj: Object = aim.collider()
	if hit_obj:
		var obj := Gamemanager.find_owner_of_group(hit_obj as Node, "Bottle")
		if obj and obj.has_method("show_label"):
			if last_label_owner and last_label_owner != obj and last_label_owner.has_method("hide_label"):
				last_label_owner.hide_label()
			obj.show_label()
			last_label_owner = obj
		else:
			_hide_label_helper()
	else:
		_hide_label_helper()


func _hide_label_helper() -> void:
	if last_label_owner and last_label_owner.has_method("hide_label"):
		last_label_owner.hide_label()
		last_label_owner = null


# ---------- Helpers ----------
func _find_parent_with_group(node: Node, group: String) -> Node:
	var cur := node
	while cur:
		if cur.is_in_group(group):
			return cur
		cur = cur.get_parent()
	return null


func _is_on_theke(obj: Node3D) -> bool:
	return obj.has_meta("on_theke") and obj.get_meta("on_theke") == true


func _apply_fov() -> void:
	camera.fov = Gamemanager.FOV


func _give_player_stuff(stuff: PackedScene) -> void:
	var obj := stuff.instantiate()
	hand_slot.add_child(obj)
	held_object = obj
	_place_handslot_z()


func _place_handslot_z() -> void:
	if held_object.is_in_group("BeerBottle"):
		hand_slot.position = Vector3(0.2, -0.1, -0.75)
	else:
		hand_slot.position.z = -0.5
		hand_slot.position.x = 0.2
		hand_slot.position.y = 0.0


# ---------- Kontext (E) ----------
func _on_use_context() -> void:
	var hit_obj: Object = aim.collider()
	if hit_obj and (hit_obj as Node).has_method("open_ui"):
		(hit_obj as Node).open_ui()
