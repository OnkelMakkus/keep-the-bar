# regal.gd
extends Node3D

@export var slots_pro_brett: int = 12
const REIHEN = 3
const SPALTEN = 4
const Z_KOORDS = [-0.15, -0.30, -0.45] # Reihenabstand (Z), Reihenfolge: vorne nach hinten
const RAND_ABSTAND = 0.07

var debug_nubsies := false

func _ready():
	var bretter = []
	for child in get_children():
		if child.is_in_group("Regalbrett"):
			bretter.append(child)
	
	for brett in bretter:
		var mesh_instance := brett as MeshInstance3D
		if mesh_instance:
			var aabb = mesh_instance.get_mesh().get_aabb()
			var breite = aabb.size.x * brett.scale.x
			var y_offset = aabb.position.y + aabb.size.y # Oberseite
			for reihe in REIHEN:
				for spalte in SPALTEN:
					var slot = Marker3D.new()
					# Gleichmäßig über die Breite verteilen
					var effektive_breite = breite - 2 * RAND_ABSTAND
					var x = -0.5 * effektive_breite  + (spalte / float(SPALTEN - 1)) * effektive_breite 
					var z = Z_KOORDS[reihe]
					slot.position = Vector3(x, y_offset, z)
					slot.name = "Slot_%02d_%02d" % [reihe, spalte]
					
					if debug_nubsies:
						if not Engine.is_editor_hint():
							var mesh = MeshInstance3D.new()
							mesh.mesh = SphereMesh.new()
							mesh.scale = Vector3(0.04, 0.04, 0.04)
							slot.add_child(mesh)

					brett.add_child(slot)
