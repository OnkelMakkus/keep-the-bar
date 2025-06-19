@tool
extends Node3D

@export var outline_material: Material = preload("res://Assets/mats/outline.tres")
@export var outline_thickness: float = 0.01

var outline_meshes := []

func _ready():
	_generate_outlines()
	set_highlight(false)

func _generate_outlines():
	# Vorherige entfernen
	for om in outline_meshes:
		if is_instance_valid(om):
			om.queue_free()
	outline_meshes.clear()

	var parent = get_parent()
	if not parent:
		return
	for child in parent.get_children():
		if child is MeshInstance3D and not child.name.ends_with("_Outline"):
			var outline = MeshInstance3D.new()
			outline.name = child.name + "_Outline"
			outline.mesh = child.mesh
			outline.transform = child.transform
			outline.material_override = outline_material.duplicate()
			outline.material_override.set("shader_parameter/thickness", outline_thickness)
			outline.material_override.set("shader_parameter/color", Color(1.0, 1.0, 0.2, 0.4))
			outline.visible = false
			self.add_child(outline)  # <- jetzt ins eigene Node
			outline_meshes.append(outline)
		elif child.get_child_count() > 0:
			_generate_outlines_recursive(child, self)

func _generate_outlines_recursive(node: Node, parent: Node):
	for child in node.get_children():
		if child is MeshInstance3D and not child.name.ends_with("_Outline"):
			var outline = MeshInstance3D.new()
			outline.name = child.name + "_Outline"
			outline.mesh = child.mesh
			outline.transform = child.transform
			outline.material_override = outline_material.duplicate()
			outline.material_override.set("shader_parameter/thickness", outline_thickness)
			outline.material_override.set("shader_parameter/color", Color(1.0, 1.0, 0.2, 0.4))
			outline.visible = false
			parent.add_child(outline)
			outline_meshes.append(outline)
		elif child.get_child_count() > 0:
			_generate_outlines_recursive(child, parent)

func set_highlight(enable: bool):
	if outline_meshes.is_empty():
		_generate_outlines()
	for om in outline_meshes:
		om.visible = enable
