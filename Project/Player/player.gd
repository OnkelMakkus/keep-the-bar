#player.gd
extends CharacterBody3D

@export_group("Player Stats")
@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 4.5
@export var gravity := 9.8

@export_group("Zero-G")
@export var fly_speed      := 0.8     # Bewegung in der Luft
@export var air_damp       := 18.0     # Bremst sanft ab
@export var max_fly_speed := 6.0  
@export var fly_vertical     := 6.0   # hoch / runter separat
@export var zero_g_fov_delta := 5.0       # +5° im Schwebe-Modus
@export var roll_speed := 45.0   # °/s

var _current_zero_g := false              # Merkt letzten Status
var _fov_tween      : Tween = null

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
var prepare_for_recycling := false
var zero_g := false

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
		rotation.y -= (event.relative.x * Gamemanager.mouse_sensitivity) / 5
		head.rotation.x -= (event.relative.y * Gamemanager.mouse_sensitivity) / 5
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
				#var hit = raycast.get_collider()
				if raycast.get_target().has_method("show_besitzer") and raycast.get_target().show_besitzer().is_in_group("Recycler"):
					hand_slot.remove_child(held_object)
					raycast.get_target().show_besitzer().store_mats(held_object)
					prepare_for_recycling = true
			drop_object()
				
		else:
			raycast.interact()
		return


	# Gießen (rechter Mausklick)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not Gamemanager.is_in_menu:
		if event.pressed:
			start_pour_animation()
		else:
			reset_pour_animation()
		return
		

func _update_zero_g_state():
	zero_g = not down_raycast.is_colliding()
	if zero_g != _current_zero_g:
		_current_zero_g = zero_g
		_tween_fov(zero_g) 

func _physics_process(delta):
	_update_zero_g_state()

	if zero_g:
		_update_zero_g(delta)
	else:
		_update_grounded(delta)
		#_align_upright(delta)
	show_bottle_label()

	if is_pouring and held_object and held_object.is_in_group("Bottle"):
		_process_pouring(delta)
		
		
func _update_grounded(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not zero_g and not Gamemanager.is_in_menu:
		velocity.y = jump_velocity

	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var dir3 = _get_move_direction()
	velocity.x = dir3.x * current_speed
	velocity.z = dir3.z * current_speed

	move_and_slide()
	
	
func _update_zero_g(delta):
	var up_down := false
	# 0) Gravitation abschalten
	velocity.y = 0.0

	# 1) Eingaben in alle Richtungen
	var dir = _get_move_direction()
	
	# Hoch / Runter mit zusätzlichem Input
	
	
	if Input.is_action_pressed("jump") and zero_g:
		dir += transform.basis.y * fly_speed * 2
		up_down = true
	if Input.is_action_pressed("move_down") and zero_g:
		dir -= transform.basis.y * fly_speed * 2
		up_down = true

	dir = dir.normalized()
	if up_down:
		velocity += dir * fly_vertical
	else:
		velocity += dir * fly_speed
		
	velocity = velocity.limit_length(max_fly_speed)

	# 2) Dämpfung, damit man nicht unendlich gleitet
	if up_down:
		velocity = velocity.move_toward(Vector3.ZERO, delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, air_damp * delta)
		
	move_and_slide()
	
	
func _tween_fov(enable_zero_g: bool):
	if _fov_tween: _fov_tween.kill()      # laufenden Tween abbrechen

	var base_fov := Gamemanager.FOV                  # dein Standard-FOV
	var target_fov := base_fov + (zero_g_fov_delta if enable_zero_g else 0.0)

	_fov_tween = create_tween()
	_fov_tween.tween_property(camera, "fov", target_fov, 0.4)\
			  .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
		
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
		var hit = raycast.get_target()
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
	
	
func _get_move_direction() -> Vector3:
	var d = Vector3.ZERO
	var f = -transform.basis.z
	var r =  transform.basis.x
	if not Gamemanager.is_in_menu:
		if Input.is_action_pressed("move_forward"):
			d += f
		if Input.is_action_pressed("move_back"):
			d -= f
		if Input.is_action_pressed("move_left"):
			d -= r
		if Input.is_action_pressed("move_right"):
			d += r
	return d


func _get_camera_axes() -> Dictionary:
	var b := head.global_transform.basis        # oder camera.global_transform.basis
	return {
		"forward": -b.z.normalized(),           # Blickrichtung
		"right"  :  b.x.normalized(),
		"up"     :  b.y.normalized()
	}
	

func _align_upright(delta):
	var up_basis = global_transform.basis
	var up = up_basis.y.normalized()

	# Zielrotation: Up = Welt Y
	var target_up = Vector3.UP
	var axis = up.cross(target_up)
	var angle = up.angle_to(target_up)

	if angle > 0.01:
		# Interpoliert zurück zur Aufrichtung
		var rot = Quaternion(axis.normalized(), angle * delta * 3.0)  # Dämpfungsgeschwindigkeit
		global_transform = Transform3D(rot, global_transform.origin) * global_transform
