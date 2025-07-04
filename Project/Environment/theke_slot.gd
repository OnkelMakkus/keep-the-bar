#theke_slot.gd
extends Marker3D

var belegt := false
var debug_nubsies := false

func _ready():
	if debug_nubsies:
		if Engine.is_editor_hint():
			return
		var mesh = MeshInstance3D.new()
		mesh.mesh = SphereMesh.new()
		mesh.scale = Vector3(0.05, 0.05, 0.05)
		add_child(mesh)
