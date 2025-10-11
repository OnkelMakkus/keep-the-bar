#gamemanager.gd (global)
extends Node

var spawnmarker
var thekemarker
var wait_marker_01
var wait_marker_02
var look_at_marker
var customer_exit
var main_ui
var serving_container
var theke
var first_exit

var theke_besetzt := false
var marker1_besetzt := false
var marker2_besetzt := false

var fullscreen := true

var ordermarkers = []
var wait_markers = []

var customers = []

var is_in_menu := false

var is_open := false

var replicator_open := false

var option_open := false

var original_materials := {}

var abstell_marker: Array[Marker3D] = []
var serving_marker: Array[Marker3D] = []
var bottle_marker: Array[Marker3D] = []

@onready var mouse_sensitivity := 0.01
@export var FOV : int = 70


@onready var og_scene : PackedScene = load("res://Project/Helper/outline_generator.tscn")
@onready var ORDER_MENU : PackedScene = load("res://Project/UI/order_menu.tscn")
@onready var OPTION_MENU : PackedScene = load("res://Project/UI/options.tscn")
@onready var GLASS_SCENE : PackedScene = load("res://Project/Items/glass.tscn")
@onready var BEER_SCENE : PackedScene = load("res://Project/Items/beer_bottle.tscn")


const CUSTOMER_MALE_NAMES = [
	"Kalle", "Robin", "Kevin", "Murat", "Sven",
	"Dieter", "Ragnar", "Jax", "Tobias", "Enrico",
	"Zarnak", "Threx", "Bo", "Gunther", "Levik",
	"Orion", "Brax", "Jens", "Korben", "Malik",
	"Rado", "Xel", "Yorr", "T'Var", "Vargo"
]

const CUSTOMER_FEMALE_NAMES = [
	"Ute", "Jaqueline", "Saskia", "Yvonne", "Uschi",
	"Zara", "Mira", "Nayla", "Chantal", "Brigitte",
	"Velia", "Kira", "Synn", "Eluna", "Trixi",
	"Ayra", "Nova", "Leena", "Vexa", "Nora",
	"T'Sari", "Myxa", "Rin", "Xanna", "Oona"
]


func _ready() -> void:
	check_if_release()
	Signalmanager.set_spawn_marker.connect(setSpawn)
	Signalmanager.set_waiting_marker_01.connect(setWaiting01)
	Signalmanager.set_waiting_marker_02.connect(setWaiting02)
	Signalmanager.set_theke_marker.connect(setTheke)
	Signalmanager.set_look_at_marker.connect(setLookAt)
	Signalmanager.set_customer_exit.connect(setCustomerExit)
	Signalmanager.set_first_exit_marker.connect(setFirstExit)
	Signalmanager.add_customer.connect(add_customer)
	Signalmanager.remove_customer.connect(remove_customer)


func update_customers() -> void:
	wait_markers = [wait_marker_01, wait_marker_02]
	for i in customers.size():
		var cust   : CharacterBody3D      = customers[i]

		var target : Vector3
		if i == 0:
			target = thekemarker.global_position
		elif i - 1 < wait_markers.size():
			target = wait_markers[i - 1].global_position
		else:
			var steps = i - wait_markers.size() + 1
			target = wait_markers.back().global_position - Vector3(0, 0, 2.0 * steps)

		cust.set_queue_target(target)    # <-- einzige Stelle
		
	
func add_customer(cust: CharacterBody3D):
	customers.append(cust)
	update_customers()
	
func remove_customer(cust: CharacterBody3D):
	customers.erase(cust)
	update_customers()
	
func check_if_release():
	if Engine.is_editor_hint():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Im Release: borderless, maximiert (pseudo-fullscreen)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		var screen := DisplayServer.window_get_current_screen()
		var size := DisplayServer.screen_get_size(screen)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
		_set_camera_fov(size)

func _set_camera_fov(screen_size: Vector2):
	#const V_FOV := 75.0                       # dein Basiswert (vertikal)
	
	# Falls du lieber horizontal fixieren willst, nimm die beiden Zeilen darunter:
	const H_FOV_DESIRED := 100.0
	var V_FOV = rad_to_deg(2.0 * atan(tan(deg_to_rad(H_FOV_DESIRED) * 0.5) / (screen_size.x / screen_size.y)))
	
	var cam := get_node_or_null("Camera3D")
	if cam:
		cam.fov = V_FOV                       # vertikale FOV in Grad

func highlight_object(obj: Node3D, state: bool):
	var outline = obj.get_node_or_null("OutlineGenerator")
	if outline and outline.has_method("set_highlight"):
		outline.set_highlight(state)		


func setSpawn(spawn: Marker3D):
	print ("Spawn_Marker: ", spawn.global_position)
	spawnmarker = spawn
	

func setTheke(theke_obj: Marker3D):
	print ("Theke_Marker: ", theke_obj.global_position)
	thekemarker = theke_obj
	ordermarkers.push_back(thekemarker)
	theke = thekemarker.get_parent()
	
	
func setWaiting01(wait_obj: Marker3D):
	print ("Waiting Marker 01: ", wait_obj.global_position)
	wait_marker_01 = wait_obj
	ordermarkers.push_back(wait_marker_01)
	
	
func setWaiting02(wait_obj: Marker3D):
	print ("Waiting Marker 02: ", wait_obj.global_position)
	wait_marker_02 = wait_obj
	print (ordermarkers)
	ordermarkers.push_back(wait_marker_02)
	
	
func setLookAt(lookAt_obj: Marker3D):
	print ("Look_At_Marker: ", lookAt_obj.global_position)
	look_at_marker = lookAt_obj
	
	
func setCustomerExit(exit: Marker3D):
	print ("Customer Exit: ", exit.global_position)
	customer_exit = exit
	
	
func setFirstExit(first_exit_marker: Marker3D):
	print ("Customer  First Exit: ", first_exit_marker.global_position)
	first_exit = first_exit_marker
	
	
func get_player():
	return get_tree().get_first_node_in_group("Player") 
	
	
func get_object(group):
	return get_tree().get_first_node_in_group(group)
	
	
func get_objects(group):
	return get_tree().get_nodes_in_group(group)
	
	
func find_owner_of_group(node: Node, group: String) -> Node:
	var cur = node
	while cur:
		if cur.is_in_group(group):
			return cur
		cur = cur.get_parent()
	return null
	
	
func deactivate_collider(held_object):
	var phys = held_object.find_child("StaticBody3D", true, false)
	if phys:
		phys.collision_layer = 0
		phys.collision_mask = 0
			
	
func reactivate_collider(held_object):
	var static_body = held_object.find_child("StaticBody3D", true, false)
	if static_body:
		static_body.collision_layer = 1
		static_body.collision_mask = 1
		print("Collider reaktiviert:", static_body, static_body.collision_layer, static_body.collision_mask)

		var shape = static_body.get_node_or_null("Col_Glass")
		if shape:
			shape.disabled = false
			print("Shape aktiviert:", shape)


func attach_outlineGenerator(to: Node3D):
	# Nur wenn nicht schon vorhanden
	if to.has_node("OutlineGenerator"):
		return
	var outline_generator = og_scene.instantiate()
	outline_generator.name = "OutlineGenerator"
	to.add_child(outline_generator)
	outline_generator.set_highlight(false)
	

func place_on_shelf(obj: Node3D, reference_point: Vector3, shelf: Node3D) -> bool:
	var slots = shelf.get_children().filter(func(n): return n is Marker3D and not n.has_meta("belegt"))
	if slots.size() == 0:
		return false
	var closest = slots[0]
	var min_dist = reference_point.distance_to(closest.global_position)
	for s in slots:
		var dist = reference_point.distance_to(s.global_position)
		if dist < min_dist:
			closest = s
			min_dist = dist
	obj.get_parent().remove_child(obj)
	shelf.add_child(obj)
	obj.global_position = closest.global_position
	obj.rotation = Vector3.ZERO
	closest.set_meta("belegt", true)
	return true
	
	
func get_mesh_sizes(mesh_instance):
	var mesh = mesh_instance.mesh
	if mesh:
		var aabb = mesh.get_aabb()
		var world_scale = mesh_instance.global_transform.basis.get_scale()
		var size_x = aabb.size.x * world_scale.x
		var size_y = aabb.size.y * world_scale.y
		var size_z = aabb.size.z * world_scale.z
		#print("Weltweite Größe:", size_x, size_y, size_z)
		return Vector3(size_x, size_y, size_z)
	return Vector3.ZERO
	
	
func get_all_free_glass_markers() -> Array:
	var all_free = []
	var tables = get_tree().get_nodes_in_group("Table")
	for table in tables:
		# Prüfen, ob die Methode existiert (falls es mal andere Nodes gibt)
		if table.has_method("get_free_glass_markers"):
			all_free += table.get_free_glass_markers()
	return all_free
	
	
# Alle Standing-Marker unter allen Tables einsammeln
func get_all_standing_markers() -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	for table in get_tree().get_nodes_in_group("Table"):
		_collect_markers_under(table, "standing_marker", result)
	return result

# Nur freie Marker (keine Children) zurückgeben
func get_all_free_standing_markers() -> Array[Marker3D]:
	var free_list: Array[Marker3D] = []
	for m in get_all_standing_markers():
		if is_instance_valid(m) and m.get_child_count() == 0:
			free_list.append(m)
	return free_list

# Ersten freien Marker (oder null) holen
func get_free_table_marker() -> Marker3D:
	for m in get_all_standing_markers():
		if is_instance_valid(m) and m.get_child_count() == 0:
			return m
	return null

# Hilfsfunktionen (rekursiv)
func get_nodes_in_group_under(parent: Node, group_name: String) -> Array:
	var result: Array = []
	_collect_nodes_in_group(parent, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	for child in node.get_children():
		if child.is_in_group(group_name):
			result.append(child)
		_collect_nodes_in_group(child, group_name, result)

# Spezialisiert: nur Marker3D sammeln
func _collect_markers_under(node: Node, group_name: String, out: Array[Marker3D]) -> void:
	for child in node.get_children():
		if child.is_in_group(group_name) and child is Marker3D:
			out.append(child)
		_collect_markers_under(child, group_name, out)
		
		
func get_free_marker(markers) -> Marker3D: 
	for marker in markers: 
		if marker.get_child_count() == 0: 
			return marker 
	return null
