#customer.gd
extends CharacterBody3D

@export var customer_name := "NPC"
@export var order_text := ""
@export var move_speed := 2.5
@export var rotation_speed := 5.0  # Rotation in Grad/Sekunde

@onready var label: Label3D = $Billboard
@onready var agent := $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AuxScene/AnimationPlayer

var rotating_to_theke := false
var target: Vector3
var reached_theke := false
var target_angle: float = 0.0
var finished_rotating := false
var exiting := false
var on_way_to_exit := false
var sex := 0  #0 = Male / 1 = Female
var arrived_and_stopped := false

func initialize(spawn: Vector3, target_from_spawner: Vector3):
	add_to_group("Customer")
	global_position = spawn
	global_position.y = 0
	target = target_from_spawner
	target.y = 0
	arrived_and_stopped = false
	agent.target_position = target
	if label:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = false

func _physics_process(delta: float) -> void:
	var destination : Vector3
	var direction : Vector3
	# 1. Wenn er zum Exit läuft
	if exiting:
		animation_player.play("Walking")
		if agent.is_navigation_finished():
			print("Distanz zum Exit:", global_position.distance_to(agent.target_position))
			print("Kunde-Pos:", global_position, "Exit-Pos:", agent.target_position)
			despawn_after_exit()
		else:
			destination = agent.get_next_path_position()
			direction = (destination - global_position).normalized()
			velocity = direction * move_speed
			look_in_movement_direction(direction, delta)
			move_and_slide()
		return

	# 2. Normale Ziel-Ankunft
	if agent.is_navigation_finished():
		if not arrived_and_stopped:
			arrived_and_stopped = true
			velocity = Vector3.ZERO
			animation_player.play("Idle")
			if not reached_theke:
				handle_theke_arrival()
		move_and_slide()
		# Rotation nach Ankunft (auch nach erster Arrival-Frame)
		if rotating_to_theke and reached_theke and not finished_rotating:
			rotate_towards_target(delta)
		return

	# 3. Auf dem Weg zum Ziel (Theke o.ä.)
	animation_player.play("Walking")
	destination = agent.get_next_path_position()
	direction = (destination - global_position).normalized()
	velocity = direction * move_speed
	if (not rotating_to_theke and direction.length() > 0.1) or on_way_to_exit:
		look_in_movement_direction(direction, delta)
	move_and_slide()

	# Drehen zur Theke, falls dran
	if rotating_to_theke and reached_theke:
		rotate_towards_target(delta)


func is_at_target() -> bool:
	return global_position.distance_to(target) <= .5  # oder 0.3, je nach Theke

func look_in_movement_direction(direction: Vector3, delta: float):
	direction.y = 0  # Nur horizontale Rotation
	var desired_angle = atan2(direction.x, direction.z) + PI
	var current_angle = rotation.y
	var new_angle = lerp_angle(current_angle, desired_angle, rotation_speed * delta)
	rotation.y = new_angle	

func handle_theke_arrival():
	print("✅ Kunde ist an der Theke.")
	reached_theke = true
	rotating_to_theke = false
	label.visible = false
	finished_rotating = false

	if is_front_customer():
		rotating_to_theke = true
		finished_rotating = false
		label.visible = true
		var to_target = (Gamemanager.look_at_marker.global_position - global_position).normalized()
		to_target.y = 0
		target_angle = atan2(to_target.x, to_target.z) + PI


func rotate_towards_target(delta):
	if finished_rotating:
		return

	var current_angle = rotation.y
	var new_angle = lerp_angle(current_angle, target_angle, rotation_speed * delta)
	rotation.y = new_angle

	if absf(target_angle - current_angle) < deg_to_rad(1):
		finished_rotating = true

func clicked_by_player():
	if not reached_theke:
		print("Kunde bewegt sich noch.")
		return

	if exiting:
		print("Kunde verlässt schon.")
		return

	if not is_front_customer():
		print("Kunde ist nicht vorne, darf nicht gehen!")
		return

	print("🚶‍♂️ Kunde verlässt die Theke...")

	var drink_served = try_serve_drink()
	update_customer_label(drink_served)
	start_leaving_sequence()

# --- Hilfsfunktionen ---

func try_serve_drink() -> bool:
	var serving_container = Gamemanager.serving_container
	if not serving_container:
		return false

	var recipe = Gamemanager.RECIPES.get(order_text, null)
	if not recipe:
		return false

	for obj in serving_container.get_children():
		if order_text == "Beer" and obj.is_in_group("BeerBottle"):
			if _beer_fits(obj, recipe):
				return _serve_and_remove(obj, recipe)
		elif obj.is_in_group("Glass"):
			if _glass_fits(obj, recipe):
				return _serve_and_remove(obj, recipe)
	return false

func _beer_fits(obj, recipe) -> bool:
	for ingredient in recipe["ingredients"]:
		if obj.volume_ml < ingredient["amount_ml"]:
			return false
	return true

func _glass_fits(obj, recipe) -> bool:
	for ingredient in recipe["ingredients"]:
		var ingr_name = ingredient["name"]
		var amount = ingredient["amount_ml"]
		if not obj.contents.has(ingr_name) or obj.contents[ingr_name] < amount:
			return false
	return true

func _serve_and_remove(obj, recipe) -> bool:
	print("🍹 Kunde bekommt sein Getränk:", order_text)
	var preis = recipe["sell_price"]
	Signalmanager.update_money.emit(preis)
	obj.queue_free()
	return true

func update_customer_label(drink_served: bool):
	if drink_served:
		label.text = "%s: %s" % [customer_name, "😊"]
	else:
		print("❌ Kein passendes oder vollständiges Getränk für Kunden gefunden:", order_text)
		label.text = "%s: %s" % [customer_name, "😞"]
	label.visible = true

func start_leaving_sequence():
	exiting = true
	arrived_and_stopped = false

	var exit_marker = Gamemanager.customer_exit
	if exit_marker:
		print("Kunde verlässt, Ziel:", exit_marker.global_position)
		remove_from_group("Customer")
		agent.target_position = exit_marker.global_position
		target = exit_marker.global_position
		target.y = 0
		arrived_and_stopped = false
		rotating_to_theke = false
		finished_rotating = false
		await get_tree().create_timer(2.0).timeout # 2 Sek. Smiley zeigen
		label.visible = false
		Signalmanager.customer_leaves_front.emit()
	else:
		print("❌ Exit-Marker nicht gefunden!")


func despawn_after_exit():
	print("👋 Kunde hat das Spielfeld verlassen.")
	queue_free()

func update_target(new_target: Vector3):
	if exiting:
		print("Update Target abgebrochen: Kunde verlässt gerade das Spielfeld.")
		return
	
	new_target.y = 0
	target = new_target
	agent.target_position = target
	rotating_to_theke = false
	finished_rotating = false
	reached_theke = false
	label.visible = false
	velocity = Vector3.ZERO
	arrived_and_stopped = false

	if is_front_customer():
		rotating_to_theke = true
		finished_rotating = false
		label.visible = true
		var to_target = (Gamemanager.look_at_marker.global_position - global_position).normalized()
		to_target.y = 0
		target_angle = atan2(to_target.x, to_target.z) + PI
		
	print("Update Target:", target, "Exiting:", exiting, "arrived_and_stopped:", arrived_and_stopped)
	show_label_if_front()

func is_front_customer() -> bool:
	var customers = get_tree().get_nodes_in_group("Customer")
	if customers.size() == 0:
		return false
	var closest = customers[0]
	var closest_dist = global_position.distance_to(Gamemanager.thekemarker.global_position)
	for c in customers:
		var d = c.global_position.distance_to(Gamemanager.thekemarker.global_position)
		if d < closest_dist:
			closest = c
			closest_dist = d
	return closest == self
	
	
func show_label_if_front():
	if is_front_customer() and not exiting:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = true
	else:
		label.visible = false
		
