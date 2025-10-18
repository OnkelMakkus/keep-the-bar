# recycler.gd
extends Node3D

@export var recycler_storage: Node3D
@export var recycler_button: MeshInstance3D
@export var replicator_button: MeshInstance3D
@export var intake_area: Area3D

var label_name := "\nRecycler/Replicator\n\nPlace things on top then \nhit red button to recycle.\n\nHit green button to replicate."
var objects_to_recycle := []

func _ready() -> void:
	Signalmanager.recycle.connect(recycle)


func store_mats(obj: Node, world_point: Vector3 = Vector3.INF, world_normal: Vector3 = Vector3.UP) -> void:
	if obj == null or not is_instance_valid(obj) or not (obj is Node3D):
		return
	if recycler_storage == null:
		return

	var n := obj as Node3D
	var gt := n.global_transform if n.is_inside_tree() else n.transform

	# sicher reparenten (keep_global)
	if n.is_inside_tree():
		n.reparent(recycler_storage, true)
	else:
		recycler_storage.add_child(n)
		n.transform = gt

	# optional: exakt am Trefferpunkt ablegen
	if world_point != Vector3.INF:
		var lift := 0.01
		var cyl := n.get_node_or_null("Cylinder") as MeshInstance3D
		if cyl and cyl.mesh:
			var h := cyl.mesh.get_aabb().size.y * n.global_transform.basis.get_scale().y
			lift = max(lift, h * 0.5 - 0.001)
		n.global_position = world_point + world_normal.normalized() * lift
		if intake_area:
			n.global_position.y = intake_area.global_position.y

	if is_instance_valid(n) and not objects_to_recycle.has(n):
		objects_to_recycle.append(n)


func recycle() -> void:
	var candidates = _collect_candidates()
	if candidates.is_empty():
		return

	for obj in candidates:
		if not is_instance_valid(obj):
			continue

		var item_id := _resolve_item_id(obj)
		if item_id != "":
			ReplicatorDB.credit_recycle(item_id)

		# Objekt entfernen (bevorzugt VFX)
		if (obj as Object).has_method("teleport_out"):
			obj.teleport_out() # async; wir warten bewusst nicht
		else:
			(obj as Node).queue_free()

	# UI updaten
	Signalmanager.update_res_display.emit()

# --- helpers ---

func _collect_candidates():
	var out: Array = []

	# 1) priorisiere vorgemerkte
	if objects_to_recycle.size() > 0:
		out = objects_to_recycle.duplicate()
		objects_to_recycle.clear()
	else:
		# 2) Intake-Area Bodies
		if intake_area:
			for b in intake_area.get_overlapping_bodies():
				if b is Node and not out.has(b):
					out.append(b)
			# optional: Areas unterstützen (falls Items als Area auftreten)
			for a in intake_area.get_overlapping_areas():
				if a is Node and not out.has(a):
					out.append(a)

		# 3) Fallback: alles aus Storage
		if recycler_storage:
			for c in recycler_storage.get_children():
				if c is Node and not out.has(c):
					out.append(c)
	return out


func _resolve_item_id(obj: Object) -> String:
	# 1) best case: Meta vom Replicator
	if (obj as Object).has_method("has_meta") and obj.has_meta("replicator_item_id"):
		var v = obj.get_meta("replicator_item_id")
		if v is String and v != "":
			return v

	# 2) Heuristik nach Gruppen/Properties
	if (obj as Node).is_in_group("BeerBottle"):
		return "Beer"

	if (obj as Node).is_in_group("Bottle"):
		# deine bottle.gd hat ingredient_name
		var ingr = obj.get("ingredient_name")
		if ingr is String and ingr != "":
			return ingr

	# 3) letzter Fallback: generisches Feld
	var w = obj.get("ingredient_name")
	if w is String and w != "":
		return w

	return ""
