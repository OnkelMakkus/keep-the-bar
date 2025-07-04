#customer.gd
extends CharacterBody3D

@export var customer_name := "NPC"
@export var order_text := ""
@export var move_speed := 2.5
@export var rotation_speed := 5.0  # Rotation in Grad/Sekunde

@export var label: Label3D
@export var agent : NavigationAgent3D
@export var y_animation_player: AnimationPlayer
@export var x_animation_player: AnimationPlayer
@export var y_bot: Node3D
@export var x_bot: Node3D
@export var collider: CollisionShape3D
@onready var raycast: RayCast3D = $RayCast3D


var animation_player: AnimationPlayer

var target: Vector3
var target_name: String
var finished_rotation := false
var reached_theke := false
var reached_first_leaving_wp := false
var going_to_table := false
var at_table := false
var leaving := false
var on_exit := false

var queue_target_active := false   # kommt vom GameManager
var queue_target : Vector3         # letzter Warteschlangen-Punkt

var first_exit_marker
var exit_marker

var sex := 1

var last_position := Vector3.ZERO
var stuck_frames := 0
var stuck_threshold := 0.01  # Maximale Bewegung pro Frame, um als "stuck" zu zählen
var stuck_max_frames := 3    # Nach wie vielen Frames gilt Agent als blockiert?

var label_name := "<E>\nGive Order\nSend away"


func _ready() -> void:
	add_to_group("Customer")


func set_queue_target(pos: Vector3) -> void:
	queue_target_active = true
	queue_target        = pos
	agent.target_position = pos
	
	
func initialize(sex_xy : int, cust_name : String, drink : String, start: Vector3):	
	global_position = start
	target = Gamemanager.thekemarker.global_position
	target_name = Gamemanager.thekemarker.name
	#target.y = 0
	agent.target_position = target
	prints("Target:", agent.target_position, "Real Target:", Gamemanager.thekemarker.global_position)
	
	customer_name = cust_name
	order_text = drink
	sex = sex_xy
	
	if sex == 0:
		animation_player = y_animation_player
		y_bot.visible = true
		x_bot.visible = false
	elif sex == 1:
		animation_player = x_animation_player
		y_bot.visible = false
		x_bot.visible = true
		
	if label:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = false
		
	first_exit_marker = Gamemanager.first_exit
	exit_marker = Gamemanager.customer_exit
	
	
func _physics_process(delta: float) -> void:
	rotation.x = 0
	global_position.y = 0.55		
	
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit.is_in_group("Customer"):
			if not going_to_table or not leaving:
				velocity = Vector3.ZERO
				return
	
	check_if_walking()
	if going_to_table:
		set_collider_enabled(false)
		
	if leaving:
		set_collider_enabled(false)
		general_agent_stuff(delta)
		
		if agent.is_navigation_finished():
			if not reached_first_leaving_wp:
				reached_first_leaving_wp = true
				target = exit_marker.global_position
				agent.target_position = target
		
			elif not on_exit:
				on_exit = true
				despawn_after_exit()
				return
			
		move_and_slide()
		return
		
	if agent.is_navigation_finished() and not leaving and not going_to_table:
		if is_at_target():
			set_collider_enabled(true)
			look_at_theke(delta)
			reached_theke = true
			Gamemanager.theke_besetzt = true
			show_label_if_theke()
		move_and_slide()
		return
	
	general_agent_stuff(delta)	
	move_and_slide()
	

func is_at_target() -> bool:	
	return global_position.distance_to(Gamemanager.thekemarker.global_position) <= 0.9  # oder 0.3, je nach Theke

func look_in_movement_direction(direction: Vector3, delta: float):
	direction.y = 0  # Nur horizontale Rotation
	var desired_angle = atan2(direction.x, direction.z) + PI
	var current_angle = rotation.y
	var new_angle = lerp_angle(current_angle, desired_angle, rotation_speed * delta)
	rotation.y = new_angle


func clicked_by_player():
	if not reached_theke:
		print("Kunde bewegt sich noch.")
		return

	if leaving:
		print("Kunde verlässt schon.")
		return

	print("🚶‍♂️ Kunde verlässt die Theke...")

	var result = try_serve_drink()
	print("Result:", result)

	if not result.has("drink_obj") or not result.has("marker_pair") or not result["drink_obj"] or not result["marker_pair"]:
		update_customer_label(false) # 😞
		leaving_now()
		return

	# Getränk an Kunde
	_serve_and_remove(result["drink_obj"], Gamemanager.RECIPES.get(order_text))
	update_customer_label(true) # 😊

	# Marker reservieren
	var pair = result["marker_pair"]
	pair["table"].marker_pairs[pair["index"]]["used"] = true

	# Zum Marker schicken, dort verweilen und dann raus
	go_to_marker_and_wait(pair)

# --- Hilfsfunktionen ---

func set_collider_enabled(enabled: bool):
	# Wenn du mehrere CollisionShape3Ds hast, für jeden aufrufen!
	collider.disabled = not enabled   
	

func general_agent_stuff(delta):
	var next_pos = agent.get_next_path_position()
	var direction = next_pos - global_transform.origin
	direction.y = 0  # Nur XZ-Ebene

	if direction.length() > 0.05:
		direction = direction.normalized()
		velocity = direction * move_speed
		look_in_movement_direction(direction, delta)
	else:
		velocity = Vector3.ZERO
		
		
func go_to_marker_and_wait(pair):
	raycast.collision_mask = 5
	Gamemanager.theke_besetzt = false
	self.remove_from_group("Customer")
	prints("Pair:",pair)
	going_to_table = true
	prints("Going to Table:", target)
	target = pair["standing_marker"].global_position
	agent.target_position = target

	# Warten bis am Marker
	while not agent.is_navigation_finished():
		await get_tree().process_frame
	
	at_table = true
	await get_tree().create_timer(10.0).timeout # z. B. 3 Sekunden Pause
	
	if not order_text == "Beer":
		var glass_marker = pair["glass_marker"]
		var glass = Gamemanager.GLASS_SCENE.instantiate()
	
		glass_marker.call_deferred("add_child", glass)
		glass.call_deferred("place_on_table_by_customer", glass_marker.global_position, pair["table"], pair["index"])
		glass._update_label()
		# Marker noch nicht freigeben!
		pair["table"].marker_pairs[pair["index"]]["used"] = true
	else:
		# Marker wieder freigeben!
		pair["table"].marker_pairs[pair["index"]]["used"] = false
	# Danach normal verlassen
	leaving_now()
	

func leaving_now():
	raycast.collision_mask = 5
	print("Im Leaving")
	self.remove_from_group("Customer")
	leaving = true
	if first_exit_marker:
		target = first_exit_marker.global_position
		agent.target_position = target
		target.y = 0
		prints("Kunde verlässt, Ziel:", first_exit_marker.global_position, "Target:", target)
		await get_tree().create_timer(2.0).timeout # 2 Sek. Smiley zeigen
		label.visible = false
	else:
		print("❌ Exit-Marker nicht gefunden!")
	
	
func look_at_theke(delta):
	var look_at_pos = Gamemanager.look_at_marker.global_position
	var new_transform = transform.looking_at(look_at_pos)
	transform  = transform.interpolate_with(new_transform, rotation_speed * delta)
	velocity = Vector3.ZERO


func check_if_walking():
	var movement = global_transform.origin.distance_to(last_position)
	if movement < stuck_threshold and not agent.is_navigation_finished():
		stuck_frames += 1
	else:
		stuck_frames = 0
		last_position = global_transform.origin

	if (stuck_frames >= stuck_max_frames) or (agent.is_navigation_finished() and not leaving):
		animation_player.play("old_fat_dude/Idle")
		agent.path_desired_distance = 0.1
	else:
		animation_player.play("old_fat_dude/Walking")
		agent.path_desired_distance = 0.2
		
		
func show_besitzer():
	return self
	

func try_serve_drink() -> Dictionary:
	var serving_container = Gamemanager.serving_container
	if not serving_container:
		return {}

	var recipe = Gamemanager.RECIPES.get(order_text, null)
	if not recipe:
		return {}

	for obj in serving_container.get_children():
		if order_text == "Beer" and obj.is_in_group("BeerBottle"):
			if _beer_fits(obj, recipe):
				var marker_pair = Gamemanager.get_free_marker_pair()
				if marker_pair:
					return {"drink_obj": obj, "marker_pair": marker_pair}
				else:
					return {}
		elif obj.is_in_group("Glass"):
			if _glass_fits(obj, recipe):
				var marker_pair = Gamemanager.get_free_marker_pair()
				if marker_pair:
					return {"drink_obj": obj, "marker_pair": marker_pair}
				else:
					return {}
	return {}


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
	

func despawn_after_exit():
	print("👋 Kunde hat das Spielfeld verlassen.")
	queue_free()
	
	
func show_label_if_theke():
	if reached_theke:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = true
	else:
		label.visible = false
		
