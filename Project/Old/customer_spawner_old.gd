# customer_spawner.gd
extends Node3D

@export var customer_scene: PackedScene
@export var spawn_interval := 4.0
@export var max_customers := 3  # So viele stehen gleichzeitig an der Theke

@onready var timer := $Timer

var spawn_marker: Marker3D
var theke_marker: Marker3D
var forward: Vector3

func _ready():
	timer.wait_time = spawn_interval
	timer.stop()
	
	if Gamemanager.spawnmarker and Gamemanager.thekemarker:
		_init_markers()
	else:
		await get_tree().create_timer(0.1).timeout
		_ready()  # Bis Marker gesetzt sind, warten
		

func _init_markers():
	Signalmanager.customer_leaves_front.connect(_on_customer_leaves_front)
	spawn_marker = Gamemanager.spawnmarker
	theke_marker = Gamemanager.thekemarker
	forward = (spawn_marker.global_position - theke_marker.global_position).normalized()
	timer.start()

func _on_timer_timeout():
	if not Gamemanager.is_open:
		return
		
	var customers = get_tree().get_nodes_in_group("Customer")
	if customers.size() < max_customers:
		spawn_customer()
	update_customer_positions()
	

func spawn_customer():
	if not Gamemanager.is_open:
		return
		
	var cust_name = ""
	var sex = 0
	if randf() < 0.5:
		cust_name = Gamemanager.CUSTOMER_MALE_NAMES.pick_random()
		sex = 0
	else:
		cust_name = Gamemanager.CUSTOMER_FEMALE_NAMES.pick_random()
		sex = 1

	var recipe_names = Resourcemanager.RECIPES.keys()
	var drink = recipe_names.pick_random()
	print("👥 Neuer Kunde in Warteschlange: ", cust_name, "Bestellt:", drink)

	var cust = customer_scene.instantiate()
	cust.customer_name = cust_name
	cust.order_text = drink
	cust.sex = sex
	get_parent().add_child(cust)
	cust.call_deferred("initialize", spawn_marker.global_position, get_customer_target_position())
	cust.set_meta("on_customer_despawned", Callable(self, "_on_customer_despawned"))


func update_customer_positions():
	var customers = get_tree().get_nodes_in_group("Customer")
	customers.sort_custom(func(a, b): 
		return a.global_position.distance_to(theke_marker.global_position) < b.global_position.distance_to(theke_marker.global_position)
	)
	var slot_dist = 2.0
	for i in range(customers.size()):
		var target = theke_marker.global_position + forward * (slot_dist * i)
		target.y = 0
		customers[i].call_deferred("update_target", target)
		customers[i].call_deferred("show_label_if_front")


func get_customer_target_position() -> Vector3:
	# Für neue Kunden: Ziel = ganz hinten anstellen
	var customers = get_tree().get_nodes_in_group("Customer")
	var slot_dist = 2.0
	var pos = theke_marker.global_position + forward * (slot_dist * customers.size())
	pos.y = 0
	return pos
		
	
func _on_customer_leaves_front():
	update_customer_positions()
