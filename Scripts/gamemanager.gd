#gamemanager.gd (global)
extends Node3D

var spawnmarker
var thekemarker
var look_at_marker
var customer_exit
var serving_container
var theke

var is_open := false

var original_materials := {}

var og_scene = preload("res://Scenes/outline_generator.tscn")

@export var money := 0

@export var INGREDIENTS = {
	"Rum": {
		"display_name": "Rum",
		"buy_price": 10,
		"material": preload("res://Assets/mats/rum_whisky.tres"),
	},
	"Whisky": {
		"display_name": "Whisky",
		"buy_price": 12,
		"material": preload("res://Assets/mats/rum_whisky.tres"),
	},
	"Wodka": {
		"display_name": "Wodka",
		"buy_price": 8,
		"material": preload("res://Assets/mats/wodka_water.tres"),
	},
	"Beer": {
		"display_name": "Beer",
		"buy_price": 3,
		"material": preload("res://Assets/mats/wodka_water.tres"),
	},
	# ... beliebig erweiterbar!
}

@export var RECIPES = {
	"Beer": {
		"display_name": "Beer",
		"sell_price": 3,
		"average_price": 3,
		"ingredients": [
			{"name": "Beer", "amount_ml": 500}
		]
	},
	"Rum": {
		"display_name": "Rum",
		"sell_price": 10,
		"average_price": 10,
		"ingredients": [
			{"name": "Rum", "amount_ml": 40}
		]
	},
	"Whisky": {
		"display_name": "Whisky",
		"sell_price": 12,
		"average_price": 12,
		"ingredients": [
			{"name": "Whisky", "amount_ml": 40}
		]
	},
	"Wodka": {
		"display_name": "Wodka",
		"sell_price": 8,
		"average_price": 8,
		"ingredients": [
			{"name": "Wodka", "amount_ml": 40}
		]
	}
}

const CUSTOMER_MALE_NAMES = [
	"Kalle", "Robin", "Kevin", "Murat", "Günther", "Sven", "Jens", "Tobias", "Enrico", "Dieter"
	# usw.
]

const CUSTOMER_FEMALE_NAMES = [
	"Ute", "Fatima", "Chantal", "Saskia", "Brigitte",  "Vera",  "Franzi", "Yvonne", "Uschi"
	# usw.
]


func _ready() -> void:
	check_if_release()
	Signalmanager.set_spawn_marker.connect(setSpawn)
	Signalmanager.set_theke_marker.connect(setTheke)
	Signalmanager.set_look_at_marker.connect(setLookAt)
	Signalmanager.set_customer_exit.connect(setCustomerExit)
	
	
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
	theke = thekemarker.get_parent()
	
	
func setLookAt(lookAt_obj: Marker3D):
	print ("Look_At_Marker: ", lookAt_obj.global_position)
	look_at_marker = lookAt_obj
	
	
func setCustomerExit(exit: Marker3D):
	print ("Customer Exit: ", exit.global_position)
	customer_exit = exit
	
	
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
