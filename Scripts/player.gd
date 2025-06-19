extends CharacterBody3D

@export var mouse_sensitivity := 0.002
@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 4.5
@export var gravity := 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var hand_slot = $Head/HandSlot
@onready var raycast = $Head/RayCast3D

var mouse_captured := true
var is_pouring := false
var held_object: Node3D = null
var pour_rate_ml := 40.0
var last_label_owner: Node = null
var quit_menu_open := false
var highlighted_object: Node3D = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		rotation.y -= event.relative.x * mouse_sensitivity
		head.rotation.x -= event.relative.y * mouse_sensitivity
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !mouse_captured and !quit_menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
		Signalmanager.switch_quitBtn_visibility.emit(false)
		return

	# Customer anklicken
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if raycast.is_colliding():
			var hit = raycast.get_collider()
			var customer = Gamemanager.find_owner_of_group(hit, "Customer")
			if customer and customer.has_method("clicked_by_player"):
				customer.clicked_by_player()
		return

	# Pickup/Drop
	if event.is_action_pressed("interact"):
		if held_object:
			drop_object()
		else:
			if raycast.is_colliding():
				var hit = raycast.get_collider()
				# Prüfe erst auf Open_Schild, sonst wie bisher Pickup
				var open_schild_owner = Gamemanager.find_owner_of_group(hit, "Open_Schild")
				if open_schild_owner:
					Signalmanager.open_shop.emit()
					return # Fertig, NICHT weiter nach Pickup suchen!
				# Wenn kein Open_Schild, dann wie gehabt Pickup versuchen
				try_pickup()
		# Wenn kein Raycast-Hit, passiert einfach nichts
		return


	# Gießen (rechter Mausklick)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			start_pour_animation()
		else:
			reset_pour_animation()
		return

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	var direction = Vector3.ZERO
	var forward = -transform.basis.z
	var right = transform.basis.x

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

	if is_pouring and held_object and held_object.is_in_group("Bottle"):
		_process_pouring(delta)

func try_pickup():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var obj = Gamemanager.find_owner_of_group(hit, "Pickupable")
		if obj:
			held_object = obj
			if held_object.has_meta("on_theke") and held_object.get_meta("on_theke"):
				Gamemanager.theke.free_slot_for_object(held_object)
				held_object.set_meta("on_theke", false)
			held_object.get_parent().remove_child(held_object)
			hand_slot.add_child(held_object)
			Gamemanager.deactivate_collider(held_object)
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

	hand_slot.remove_child(held_object)
	get_parent().add_child(held_object)

	var placed := false

	if raycast.is_colliding():
		var hit = raycast.get_collider()
		var hit_parent = hit.get_parent()

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
		held_object.global_position = raycast.get_collision_point()
		print("⚪ Freie Platzierung (irgendwo)")

	Gamemanager.reactivate_collider(held_object)
	held_object = null

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
	camera.fov = 50
	is_pouring = true
	if held_object and held_object.has_method("start_pouring"):
		held_object.start_pouring()

func reset_pour_animation():
	camera.fov = 75
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
