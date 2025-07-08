#glas.gd
extends Node3D

@export var glass_liquid: Node3D
@export var teleport: Node3D 
@export var mesh: MeshInstance3D


@export var fill_ml := 0.0
@export var max_fill_ml := 250.0
@export var liquid_offset := 0.05

@export var ingredient_name := "Glass"

@export var staticBodies:Array[StaticBody3D]

var glass_liquid_mesh: MeshInstance3D
var contents := {}  # z.B. { "Rum": 40.0, "Wasser": 20.0 }

var current_scale = scale
var size
var label_name := "Glass\n<E> to pick up"
var current_table
var current_index

var dirty := false

func throw(direction: Vector3, force := 10.0):
	self.linear_velocity = direction.normalized() * force
	self.angular_velocity = Vector3(
		randf() * 10.0,
		randf() * 10.0,
		randf() * 10.0
	)

func set_obj_scale():
	scale = current_scale

func _ready():
	size = Gamemanager.get_mesh_sizes($Cylinder)
	glass_liquid_mesh = glass_liquid.get_child(0)
	teleport.scale =Vector3(0.5, 0.2, 0.5)
	teleport.start(mesh, teleport.scale, self, false)
	
	_update_visuals()
	
	Gamemanager.attach_outlineGenerator(self)
	
	
func place_on_table_by_customer(pos, table, index):
	dirty = true
	_update_label()
	global_position = pos
	current_table = table
	current_index = index
	
	
func remove_from_table():
	var table = self.get_parent().get_parent()
	if current_table and current_index >= 0:
		current_table.marker_pairs[current_index]["used"] = false
	
	
func show_label():
	_update_label()
	

func hide_label():
	pass
	

func add_liquid(liquid_name: String, amount: float) -> float:
	var total_ml = get_total_fill_ml()
	var available_space = max_fill_ml - total_ml
	var actual_added = min(amount, available_space)
	if actual_added <= 0.0:
		return 0.0
	contents[liquid_name] = (contents.get(liquid_name, 0.0)) + actual_added
	_set_liquid_material(liquid_name)
	_update_visuals()
	_update_label()
	return actual_added
	

func remove_liquid(liquid_name: String, amount: float) -> float:
	var in_glass = contents.get(liquid_name, 0.0)
	var actual_removed = min(amount, in_glass)
	if actual_removed > 0.0:
		contents[liquid_name] = in_glass - actual_removed
		if contents[liquid_name] <= 0.0:
			contents.erase(liquid_name)
	_update_visuals()
	_update_label()
	return actual_removed
	

func _set_liquid_material(liquid_name: String):
	var ing = Resourcemanager.INGREDIENTS.get(liquid_name)
	if ing:
		var mat = ing.get("material")
		if mat and glass_liquid_mesh:
			glass_liquid_mesh.material_override = mat
			

func get_total_fill_ml() -> float:
	var sum := 0.0
	for v in contents.values():
		sum += v
	return sum
	

func _update_label():
	if contents.size() == 0:
		label_name = "Glass" + "\n<E> to pick up"
		if dirty:
			label_name = "Dirty " + label_name
		return
	
	var text = ""	
	for k in contents.keys():
		text += "%s (%d ml)\n" % [k, contents[k]]
		
	label_name = "Glass\n" + text.strip_edges() + "\n<E> to pick up"
	if dirty:
		label_name = "Dirty " + label_name
	
	

func set_liquid(amount: float):
	fill_ml = clamp(amount, 0.0, max_fill_ml)
	_update_visuals()
	

func _update_visuals():
	var total_ml = get_total_fill_ml()
	var fill_level = total_ml / max_fill_ml if max_fill_ml > 0 else 0.0
	glass_liquid.scale.y = fill_level

	var vis_mesh = glass_liquid_mesh.mesh
	if vis_mesh:
		var mesh_height = vis_mesh.get_aabb().size.y
		glass_liquid.position.y = liquid_offset - (1.0 - fill_level) * 0.5 * mesh_height
	_update_label()

# Snap-to-regal bleibt erhalten:
func place_on_shelf(reference_point: Vector3, shelf: MeshInstance3D) -> bool:
	return Gamemanager.place_on_shelf(self, reference_point, shelf)
	

func activate_coliders():
	if staticBodies:
		for body in staticBodies:
			body.collision_layer = 1
			body.collision_mask = 1
			for child in body.get_children():
				if child is CollisionShape3D:
					child.disabled = false
	

func deactivate_coliders():
	if staticBodies:
		for body in staticBodies:
			body.collision_layer = 0
			body.collision_mask = 0
			for child in body.get_children():
				if child is CollisionShape3D:
					child.disabled = true
		
		
func let_it_fall(fall_position):
	await get_tree().physics_frame
	global_position = fall_position
	activate_coliders()
	
	
func despawn():
	teleport.start(mesh, teleport.scale, self, true)
	
