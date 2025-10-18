# customer.gd (neu)
extends CharacterBody3D

@export var customer_name := "NPC"
@export var order_text := ""
@export var move_speed := 2.5
@export var rotation_speed := 5.0

@export var label: Label3D
@export var label_background: Sprite3D

@export var agent : NavigationAgent3D
@export var y_animation_player: AnimationPlayer
@export var x_animation_player: AnimationPlayer
@export var test_animation_player: AnimationPlayer
@export var y_bot: Node3D
@export var x_bot: Node3D
@export var test_model : Node3D
@export var collider: CollisionShape3D

@export var teleport_mat: ShaderMaterial
@onready var raycast: RayCast3D = $RayCast3D

@export var warp_out: AudioStreamPlayer3D
@export var warp_in: AudioStreamPlayer3D

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
var _serve_lock := false

var queue_target_active := false
var queue_target : Vector3

var first_exit_marker
var exit_marker
var table_marker

var sex := 1

var last_position := Vector3.ZERO
var stuck_frames := 0
var stuck_threshold := 0.01
var stuck_max_frames := 3

var label_name := "<LMB>\nGive Order\nSend away"


func _ready() -> void:
	add_to_group("Customer")
	Signalmanager.close_store.connect(despawn_after_exit)


func teleport_out() -> void:
	if sex == 0:
		VFX.teleport_out($y_bot/Node/Skeleton3D/Alpha_Surface, teleport_mat, 2.0, false)
		VFX.teleport_out($y_bot/Node/Skeleton3D/Alpha_Joints, teleport_mat, 2.0, false)
	if sex == 1:
		VFX.teleport_out($x_bot/Node/Skeleton3D/Beta_Surface, teleport_mat, 2.0, false)
		VFX.teleport_out($x_bot/Node/Skeleton3D/Beta_Joints, teleport_mat, 2.0, false)
	warp_out.play()
	await get_tree().create_timer(2.0).timeout
	queue_free()


func set_queue_target(pos: Vector3) -> void:
	queue_target_active = true
	queue_target = pos
	agent.target_position = pos


func initialize(sex_xy : int, cust_name : String, drink : String, start: Vector3):
	var dur := 2.0
	global_position = start
	customer_name = cust_name
	order_text = drink
	sex = sex_xy

	if sex == 0:
		animation_player = y_animation_player
		y_bot.visible = true; x_bot.visible = false; test_model.visible = false
		VFX.teleport_in($y_bot/Node/Skeleton3D/Alpha_Surface, teleport_mat, dur)
		VFX.teleport_in($y_bot/Node/Skeleton3D/Alpha_Joints, teleport_mat, dur)
	elif sex == 1:
		animation_player = x_animation_player
		y_bot.visible = false; x_bot.visible = true; test_model.visible = false
		VFX.teleport_in($x_bot/Node/Skeleton3D/Beta_Surface, teleport_mat, dur)
		VFX.teleport_in($x_bot/Node/Skeleton3D/Beta_Joints, teleport_mat, dur)
	else:
		animation_player = test_animation_player
		y_bot.visible = false; x_bot.visible = false; test_model.visible = true

	if label:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = false

	warp_in.play()
	await get_tree().create_timer(2.0).timeout

	target = Gamemanager.thekemarker.global_position
	target_name = Gamemanager.thekemarker.name
	agent.target_position = target

	first_exit_marker = Gamemanager.first_exit
	exit_marker = Gamemanager.customer_exit


func _physics_process(delta: float) -> void:
	rotation.x = 0
	global_position.y = 0.55

	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit and hit.is_in_group("Customer"):
			if not going_to_table or not leaving:
				velocity = Vector3.ZERO
				check_if_walking()
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

	if agent.is_navigation_finished() and at_table and not leaving:
		look_at(table_marker.global_position)
		rotation.x = 0.0
		rotation.z = 0.0

	general_agent_stuff(delta)
	move_and_slide()


func is_at_target() -> bool:
	return global_position.distance_to(Gamemanager.thekemarker.global_position) <= 0.9


func look_in_movement_direction(direction: Vector3, delta: float):
	direction.y = 0
	var desired_angle = atan2(direction.x, direction.z) + PI
	var current_angle = rotation.y
	var new_angle = lerp_angle(current_angle, desired_angle, rotation_speed * delta)
	rotation.y = new_angle


func clicked_by_player(item: Node = null) -> void:
	if not reached_theke: return
	if leaving: return

	# direkt übergebenes Item bevorzugen; sonst wie bisher den neuesten vom Serving-Container nehmen
	var candidate: Node = item
	if candidate == null:
		candidate = Gamemanager._latest_serving_item_from_player()

	var result := try_serve_drink_with(candidate)
	if result.is_empty() or not result.has("marker_pair") or not result["marker_pair"]:
		update_customer_label(false)

		# Item robust zurückgeben/ablegen, wenn vorhanden
		if candidate and is_instance_valid(candidate):
			var pi := Gamemanager.player_interaction
			var player_holds := (pi != null and pi.held_object != null)

			if not player_holds and pi and pi.has_method("take_into_hand"):
				candidate.remove_meta("__from_player")
				candidate.remove_meta("__drop_time")
				pi.take_into_hand(candidate)
			else:
				candidate.remove_meta("__from_player")
				candidate.remove_meta("__drop_time")
				if not Gamemanager.place_on_best_marker(candidate, "abstell", candidate.global_position):
					candidate.set_meta("on_theke", true)
					if Gamemanager.theke and Gamemanager.theke.has_node("position_marker"):
						var pm := Gamemanager.theke.get_node("position_marker") as Node3D
						if pm:
							candidate.global_position.y = pm.global_position.y

		despawn_after_exit()
		return

	# Erfolg
	update_customer_label(true)
	var pair = result["marker_pair"]
	if candidate and is_instance_valid(candidate):
		if candidate.has_meta("__from_player"): candidate.remove_meta("__from_player")
		if candidate.has_meta("__drop_time"):   candidate.remove_meta("__drop_time")
	go_to_marker_and_wait(pair)



# --- Hilfsfunktionen ---

func set_collider_enabled(enabled: bool):
	collider.disabled = not enabled


func general_agent_stuff(delta):
	var next_pos = agent.get_next_path_position()
	var direction = next_pos - global_transform.origin
	direction.y = 0
	if direction.length() > 0.05:
		direction = direction.normalized()
		velocity = direction * move_speed
		look_in_movement_direction(direction, delta)
	else:
		velocity = Vector3.ZERO


func go_to_marker_and_wait(pair: Dictionary) -> void:
	raycast.collision_mask = 5
	Gamemanager.theke_besetzt = false
	self.remove_from_group("Customer")

	going_to_table = true
	target = pair["standing_marker"].global_position
	agent.target_position = target
	table_marker = pair["standing_marker"].get_parent().LookAt_Marker

	# Ankommen
	while not agent.is_navigation_finished():
		await get_tree().process_frame

	at_table = true

	# „Trinkzeit“
	var drinking_time = randf_range(3.0, 30.0)
	await get_tree().create_timer(drinking_time).timeout

	# Deko-Objekt am Tisch ablegen (einfaches Spawn, Inhalte sind bereits „konsumiert“)
	var glass_marker: Marker3D = pair["glass_marker"]
	if glass_marker:
		if order_text == "Beer":
			var beer := Gamemanager.BEER_SCENE.instantiate()
			glass_marker.call_deferred("add_child", beer)
			beer.call_deferred("place_on_table_by_customer", glass_marker.global_position, pair["table"], pair["index"])
		else:
			var glass := Gamemanager.GLASS_SCENE.instantiate()
			glass_marker.call_deferred("add_child", glass)
			glass.call_deferred("place_on_table_by_customer", glass_marker.global_position, pair["table"], pair["index"])
			if glass.has_method("_update_label"):
				glass._update_label()

	# Reservierung freigeben
	Gamemanager.clear_place_reservation(pair)

	# Danach normal verlassen
	despawn_after_exit()


func look_at_theke(delta):
	var look_at_pos = Gamemanager.look_at_marker.global_position
	var new_transform = transform.looking_at(look_at_pos)
	transform = transform.interpolate_with(new_transform, rotation_speed * delta)
	velocity = Vector3.ZERO


func check_if_walking():
	var movement = global_transform.origin.distance_to(last_position)
	if movement < stuck_threshold and not agent.is_navigation_finished():
		stuck_frames += 1
	else:
		stuck_frames = 0
		last_position = global_transform.origin

	if (stuck_frames >= stuck_max_frames) or (agent.is_navigation_finished() and not leaving):
		if sex == 2:
			animation_player.play("Untitled_Idle")
		else:
			animation_player.play("old_fat_dude/Idle")
		agent.path_desired_distance = 0.1
	else:
		if sex == 2:
			animation_player.play("Untitled_Walking")
		else:
			animation_player.play("old_fat_dude/Walking")
		agent.path_desired_distance = 0.2


func show_besitzer():
	return self


# ---------- NEU: zentrales Serve (Resources via Gamemanager) ----------
func try_serve_drink(giving_obj: Node3D = null) -> Dictionary:
	if giving_obj and is_instance_valid(giving_obj):
		var r := Gamemanager.attempt_serve(self, giving_obj)
		if r.ok:
			return {"marker_pair": r.place, "price": r.price}
	return {}

func try_serve_drink_with(obj: Node) -> Dictionary:
	# wenn kein direktes Objekt mitkommt, verhalte dich wie bisher
	if obj == null:
		return try_serve_drink()
	var res := Gamemanager.attempt_serve(self, obj)
	if res.ok:
		return {"marker_pair": res.place, "price": res.price}
	return {}


func update_customer_label(drink_served: bool):
	if drink_served:
		label.text = "%s: %s" % [customer_name, "😊"]
	else:
		print("❌ Kein passendes oder vollständiges Getränk für Kunden gefunden:", order_text)
		label.text = "%s: %s" % [customer_name, "😞"]
	label.visible = true


func despawn_after_exit():
	print("👋 Kunde hat das Spielfeld verlassen.")
	if self.is_in_group("Customer"):
		self.remove_from_group("Customer")
	if sex == 1 or sex == 0:
		teleport_out()


func show_label_if_theke():
	if reached_theke:
		label.text = "%s: %s" % [customer_name, order_text]
		label.visible = true
	else:
		label.visible = false
