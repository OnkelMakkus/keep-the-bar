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
	spawn_marker = Gamemanager.spawnmarker
	theke_marker = Gamemanager.thekemarker
	forward = (spawn_marker.global_position - theke_marker.global_position).normalized()
	timer.start()
	
	
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

	var recipe_names = Gamemanager.RECIPES.keys()
	var drink = recipe_names.pick_random()
	print("👥 Neuer Kunde in Warteschlange: ", cust_name, "Bestellt:", drink)

	var cust = customer_scene.instantiate()
	get_parent().call_deferred("add_child", cust)
	cust.call_deferred("initialize",sex, cust_name, drink, spawn_marker.global_position)
	

func _on_timer_timeout():
	if not Gamemanager.is_open:
		return
		
	var customers = get_tree().get_nodes_in_group("Customer")
	if customers.size() < max_customers:
		spawn_customer()
	
