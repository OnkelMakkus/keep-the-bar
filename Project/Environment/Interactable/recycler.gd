# recycler.gd
extends Node3D

@export var recycler_storage: Node3D
@export var recycler_button: MeshInstance3D
@export var replicator_button: MeshInstance3D
@export var intake_area: Area3D    # <- NEU (drag & drop auf deine Area)

var label_name := "\nRecycler/Replicator\n\nPlace things on top then \nhit red button to recycle.\n\nHit green button to replicate."
var objects_to_recycle: Array = []

func _ready() -> void:
	Signalmanager.recycle.connect(recycle)

func store_mats(obj: Node, world_point: Vector3 = Vector3.INF, world_normal: Vector3 = Vector3.UP) -> void:
	if obj == null:
		return

	# 1) Welt-Transform sichern
	var gt := (obj as Node3D).global_transform

	# 2) aus altem Parent lösen (falls vorhanden)
	var parent := obj.get_parent()
	if parent and parent != recycler_storage:
		parent.remove_child(obj)

	# 3) unter Storage parenten
	if obj.get_parent() != recycler_storage:
		recycler_storage.add_child(obj)

	# 4) Welt-Transform wiederherstellen
	(obj as Node3D).global_transform = gt

	# 5) Falls ein Kollisionspunkt übergeben wurde: dort abstellen (+ kleiner Lift)
	if world_point != Vector3.INF:
		var lift := 0.01
		# Optional: Unterkante exakt auf Fläche setzen, wenn Mesh vorhanden
		var cyl := (obj as Node3D).get_node_or_null("Cylinder") as MeshInstance3D
		if cyl and cyl.mesh:
			var h := cyl.mesh.get_aabb().size.y * (obj as Node3D).global_transform.basis.get_scale().y
			lift = max(lift, h * 0.5 - 0.001)
		(obj as Node3D).global_position = world_point + world_normal.normalized() * lift
		(obj as Node3D).global_position.y = intake_area.global_position.y

	# 6) Liste pflegen
	if not objects_to_recycle.has(obj):
		objects_to_recycle.append(obj)


func recycle() -> void:
	var candidates: Array = []

	# 1) Priorität: Alles, was schon „eingelagert“ wurde
	if objects_to_recycle.size() > 0:
		candidates = objects_to_recycle.duplicate()
		objects_to_recycle.clear()
	else:
		# 2) Dinge, die auf der Fläche liegen (über Area)
		if intake_area:
			for b in intake_area.get_overlapping_bodies():
				if b is Node:
					candidates.append(b)
		# 3) Fallback: Kinder von recycler_storage
		for c in recycler_storage.get_children():
			if c is Node and not candidates.has(c):
				candidates.append(c)

	if candidates.size() == 0:
		return

	for obj in candidates:
		# robust Ingredient ermitteln
		var ing_name := ""
		if (obj as Object).has_method("get"):
			var v = obj.get("ingredient_name")
			if v is String:
				ing_name = v

		if ing_name != "" and Resourcemanager.INGREDIENTS.has(ing_name):
			var mats = Resourcemanager.INGREDIENTS[ing_name]["print_mats"]
			var matter := int(ceil(float(mats.get("Matter", 0)) / 2.0))
			Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"] += matter

		# Entfernen/Despawn
		if (obj as Object).has_method("despawn"):
			obj.despawn()
		else:
			obj.queue_free()

	Signalmanager.update_res_display.emit()
