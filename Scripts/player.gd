#player.gd
extends CharacterBody3D

@export_group("Player Stats")
@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 4.5
@export var gravity := 9.8

@export_group("Nodes")
@export var head: Node3D
@export var camera: Camera3D
@export var hand_slot: Node3D
@export var raycast: RayCast3D
@export var down_raycast: RayCast3D

var mouse_captured := true
var is_pouring := false
var held_object: Node3D = null
var pour_rate_ml := 40.0
var last_label_owner: Node = null
var quit_menu_open := false
var highlighted_object: Node3D = null
var prepare_for_recycling := false

var is_picking_up = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.give_player_stuff.connect(give_player_stuff)
	Signalmanager.change_fov.connect(change_fov)
	
	Signalmanager.change_fov.emit()


func give_player_stuff(stuff: PackedScene):
	var obj = stuff.instantiate()
	hand_slot.add_child(obj)
	held_object = obj
	held_object.deactivate_coliders()
	place_handslot_z()
	
	
func place_handslot_z():
	if held_object.is_in_group("BeerBottle"):
		hand_slot.position.z = -0.75
		hand_slot.position.x = 0.2
		hand_slot.position.y = -0.1
	else:
		hand_slot.position.z = -0.5 - held_object.size.z
		hand_slot.position.x = 0.2 + held_object.size.x
		hand_slot.position.y = 0 - (held_object.size.y/2)
	
	
func _input(event):	
	if event is InputEventMouseMotion and mouse_captured and not Gamemanager.is_in_menu:
		rotation.y -= event.relative.x * Gamemanager.mouse_sensitivity
		head.rotation.x -= event.relative.y * Gamemanager.mouse_sensitivity
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !mouse_captured and !quit_menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
		Signalmanager.switch_quitBtn_visibility.emit(false)
		return
			
	if event.is_action_pressed("drop") and not Gamemanager.is_in_menu:
		if held_object:
			if down_raycast.is_colliding():
				var hit = down_raycast.get_collider()
				var hit_position = down_raycast.get_collision_point()
				print(hit_position)
				held_object.let_it_fall(hit_position)
				hand_slot.remove_child(held_object)
				get_parent().add_child(held_object)
				
				held_object = null
			
			
	# Pickup/Drop
	if event.is_action_pressed("interact") and not Gamemanager.is_in_menu:
		if held_object:
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				if hit.has_method("show_besitzer") and hit.show_besitzer().is_in_group("Recycler"):
					hand_slot.remove_child(held_object)
					hit.show_besitzer().store_mats(held_object)
					prepare_for_recycling = true
			drop_object()
				
		else:
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				
				var recycler_owner = Gamemanager.find_owner_of_group(hit, "Recycler_Button")
				if recycler_owner:
					Signalmanager.recycle.emit()
					return
					
				var open_schild_owner = Gamemanager.find_owner_of_group(hit, "Open_Schild")
				if open_schild_owner:
					Signalmanager.open_shop.emit()
					return 
					
				var order_schild_owner = Gamemanager.find_owner_of_group(hit, "Order_Schild")
				if order_schild_owner:
					Signalmanager.open_order.emit()
					return 
					
				var replicator_owner = Gamemanager.find_owner_of_group(hit, "Replicator")
				if replicator_owner and not Gamemanager.replicator_open:
					replicator_owner.open_ui()
					return
				
				var customer = Gamemanager.find_owner_of_group(hit, "Customer")
				if customer and customer.has_method("clicked_by_player") and not held_object:
					
					customer.clicked_by_player()
					return
				
				try_pickup()
		# Wenn kein Raycast-Hit, passiert einfach nichts
		return


	# Gießen (rechter Mausklick)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not Gamemanager.is_in_menu:
		if event.pressed:
			start_pour_animation()
		else:
			reset_pour_animation()
		return
		

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump") and not Gamemanager.is_in_menu:
			velocity.y = jump_velocity

	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var direction = Vector3.ZERO
	var forward = -transform.basis.z
	var right = transform.basis.x

	if not Gamemanager.is_in_menu:
		if Input.is_action_pressed("move_forward"):
			direction += forward
		if Input.is_action_pressed("move_back"):
			direction -= forward
		if Input.is_action_pressed("move_left"):
			direction -= right
		if Input.is_action_pressed("move_right"):
			direction += right
		
		direction = direction.normalized()
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		move_and_slide()
	update_highlight()
	show_bottle_label()
	check_which_object_it_is()

	if is_pouring and held_object and held_object.is_in_group("Bottle"):
		_process_pouring(delta)
		
		
func check_which_object_it_is():
	if !raycast.is_colliding():
		Signalmanager.update_info_label.emit("")
		return

	var hit = raycast.get_collider()
	if hit == null:
		Signalmanager.update_info_label.emit("")
		return
		
	if !hit.has_method("show_besitzer"):
		Signalmanager.update_info_label.emit("")
		return

	var besitzer = hit.show_besitzer()
		
	if besitzer == null:
		Signalmanager.update_info_label.emit("")
		return
		
	if (besitzer.has_method("clicked_by_player") or not besitzer.has_method("clicked_by_player")):
		Signalmanager.update_info_label.emit(besitzer.label_name)
	else:
		Signalmanager.update_info_label.emit("")


func try_pickup():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var obj = Gamemanager.find_owner_of_group(hit, "Pickupable")
		if obj:
			held_object = obj
			place_handslot_z()
			if held_object.is_in_group("bottle_box"):
				if held_object.is_in_group("beer_bottle_box"):
					for key in Gamemanager.boxes.keys():
						var group_name = Gamemanager.boxes[key]["group"]
						if held_object.is_in_group(group_name):
							var scene = Gamemanager.boxes[key]["res"]
							if scene is PackedScene:
								var held_kiste = scene.instantiate()
								print ("Swapping prefaps...")
								hand_slot.add_child(held_kiste)
								held_object.queue_free()
								held_object = held_kiste
								print ("swapped")
								return
				
			held_object.deactivate_coliders()
			await get_tree().process_frame
			if held_object.has_meta("on_theke") and held_object.get_meta("on_theke"):
				Gamemanager.theke.free_slot_for_object(held_object)
				held_object.set_meta("on_theke", false)
			held_object.get_parent().remove_child(held_object)
			hand_slot.add_child(held_object)
			
			if held_object.has_method("remove_from_table"):
				held_object.remove_from_table()
			
			held_object.transform = Transform3D.IDENTITY
			held_object.rotation = Vector3.ZERO
			if held_object.is_in_group("BeerBottle"):
				held_object.set_obj_scale()
			# Connecte das Pour-Ende Signal!
			if held_object.has_signal("finished_pouring"):
				# Try disconnect, ignoriere Fehler falls noch nicht verbunden
				if held_object.is_connected("finished_pouring", Callable(self, "reset_pour_animation")):
					held_object.disconnect("finished_pouring", Callable(self, "reset_pour_animation"))
				held_object.connect("finished_pouring", Callable(self, "reset_pour_animation"))
		else:
			print("Kein gültiges Objekt zum Aufnehmen.")
			

func drop_object():
	if not held_object:
		return
	
	if not prepare_for_recycling:
		hand_slot.remove_child(held_object)
		get_parent().add_child(held_object)

	var placed := false

	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var hit_parent = hit.get_parent()
		print(hit.get_groups(), hit.name, held_object.name)
		if held_object.is_in_group("Glass") or held_object.is_in_group("BeerBottle"):
			print ("Glass or Bottle")
			if  hit.is_in_group("Customer"):
				held_object.get_parent().remove_child(held_object)
				Gamemanager.serving_container.add_child(held_object)
				held_object.set_meta("on_theke", true)
				held_object.global_position = raycast.get_collision_point()
				if held_object.is_in_group("BeerBottle"):
					held_object.set_obj_scale()
				placed = true
				print("✅ Objekt auf Theke frei platziert.", held_object, held_object.global_transform)
				hit.clicked_by_player()
				held_object.activate_coliders()
				held_object = null
				prepare_for_recycling = false
				return

		if held_object.has_signal("finished_pouring") and held_object.is_connected("finished_pouring", Callable(self, "reset_pour_animation")):
			held_object.disconnect("finished_pouring", Callable(self, "reset_pour_animation"))
		if held_object.has_method("place_on_shelf") and hit_parent and hit_parent.is_in_group("Regalbrett"):
			if held_object.place_on_shelf(raycast.get_collision_point(), hit_parent):
				placed = true
				print("✅ Auf Regalbrett platziert (Slot)")

		elif find_parent_with_group(hit, "Theke"):
			held_object.get_parent().remove_child(held_object)
			Gamemanager.serving_container.add_child(held_object)
			held_object.set_meta("on_theke", true)
			held_object.global_position = raycast.get_collision_point()
			if held_object.is_in_group("BeerBottle"):
				held_object.set_obj_scale()
			placed = true
			print("✅ Objekt auf Theke frei platziert.", held_object, held_object.global_transform)

		if not placed:
			if hit.is_in_group("Customer"):
				get_parent().remove_child(held_object)
				hand_slot.add_child(held_object)
				held_object.global_position = hand_slot.global_position
				return
				
			held_object.global_position = raycast.get_collision_point()
			print("⚪ Freie Platzierung (irgendwo)")

	held_object.activate_coliders()
	held_object = null
	prepare_for_recycling = false


func find_parent_with_group(node: Node, group: String) -> Node:
	var cur = node
	while cur:
		if cur.is_in_group(group):
			return cur
		cur = cur.get_parent()
	return null

func _process_pouring(delta):
	# Einzige Aufgabe: Sag der Bottle, was zu tun ist!
	var glass = null
	if raycast.is_colliding():
		var target = raycast.get_collider()
		glass = Gamemanager.find_owner_of_group(target, "Glass")
	if glass and glass.is_in_group("Glass") and is_object_on_theke(glass):
		held_object.try_pour_into(glass, pour_rate_ml * delta)
	else:
		reset_pour_animation()
		

func start_pour_animation():
	camera.fov = Gamemanager.FOV
	hand_slot.position.z -= 0.4
	hand_slot.position.y += 0.2
	hand_slot.position.x += 0.1
	is_pouring = true
	if held_object and held_object.has_method("start_pouring"):
		held_object.start_pouring()
		

func reset_pour_animation():
	camera.fov = Gamemanager.FOV
	hand_slot.position.z += 0.4
	hand_slot.position.y -= 0.2
	hand_slot.position.x -= 0.1
	is_pouring = false
	if held_object and held_object.has_method("stop_pouring"):
		held_object.stop_pouring()
		

func is_object_on_theke(obj: Node3D) -> bool:
	return obj.has_meta("on_theke") and obj.get_meta("on_theke") == true
	

func update_highlight():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var obj = Gamemanager.find_owner_of_group(hit, "Pickupable")
		if obj:
			if highlighted_object and highlighted_object != obj:
				Gamemanager.highlight_object(highlighted_object, false)
			Gamemanager.highlight_object(obj, true)
			highlighted_object = obj
		else:
			if highlighted_object:
				Gamemanager.highlight_object(highlighted_object, false)
				highlighted_object = null
	else:
		if highlighted_object:
			Gamemanager.highlight_object(highlighted_object, false)
			highlighted_object = null
			

func show_bottle_label():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var obj = Gamemanager.find_owner_of_group(hit, "Bottle")
		if obj and obj.has_method("show_label"):
			if last_label_owner and last_label_owner != obj and last_label_owner.has_method("hide_label"):
				last_label_owner.hide_label()
			obj.show_label()
			last_label_owner = obj
		else:
			hide_label_helper()
	else:
		hide_label_helper()
		

func hide_label_helper():
	if last_label_owner and last_label_owner.has_method("hide_label"):
		last_label_owner.hide_label()
		last_label_owner = null
		

func change_fov():
	camera.fov = Gamemanager.FOV
