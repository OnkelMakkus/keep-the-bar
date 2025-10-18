# VFX.gd
extends Node

func teleport_in(mesh: MeshInstance3D, teleport_mat: ShaderMaterial, duration: float = 2.0) -> void:
	if not is_instance_valid(mesh) or teleport_mat == null:
		return
	mesh.material_overlay = teleport_mat
	teleport_mat.set_shader_parameter("t", 1.0)
	teleport_mat.set_shader_parameter("overall_alpha", 0.0)

	# kurzes Fade-In
	var fade_in := 0.2
	var fi_steps := 12
	for i in range(fi_steps):
		var a := float(i + 1) / fi_steps
		if not is_instance_valid(mesh): return
		teleport_mat.set_shader_parameter("overall_alpha", a)
		await mesh.get_tree().create_timer(fade_in / fi_steps).timeout

	# t: 1 -> 0
	var steps := 60
	for i in range(steps + 1):
		var v := 1.0 - float(i) / steps
		if not is_instance_valid(mesh): return
		teleport_mat.set_shader_parameter("t", v)
		await mesh.get_tree().create_timer(duration / steps).timeout

	# kurzes Fade-Out
	var fade_out := 0.2
	var fo_steps := 12
	for j in range(fo_steps):
		var a := 1.0 - float(j + 1) / fo_steps
		if not is_instance_valid(mesh): return
		teleport_mat.set_shader_parameter("overall_alpha", a)
		await mesh.get_tree().create_timer(fade_out / fo_steps).timeout

	if is_instance_valid(mesh):
		mesh.material_overlay = null

func teleport_out(mesh: MeshInstance3D, teleport_mat: ShaderMaterial, duration: float = 2.0, free_after: bool = true) -> void:
	if not is_instance_valid(mesh) or teleport_mat == null:
		return
	mesh.material_overlay = teleport_mat
	teleport_mat.set_shader_parameter("t", 0.0)
	teleport_mat.set_shader_parameter("overall_alpha", 1.0)

	var steps := 60
	for i in range(steps + 1):
		var v := float(i) / steps  # 0 -> 1
		if not is_instance_valid(mesh): return
		teleport_mat.set_shader_parameter("t", v)
		await mesh.get_tree().create_timer(duration / steps).timeout

	# kleines Fade-Out (0.3s)
	var fade_steps := 15
	for j in range(fade_steps):
		var a := 1.0 - float(j + 1) / fade_steps
		if not is_instance_valid(mesh): return
		teleport_mat.set_shader_parameter("overall_alpha", a)
		await mesh.get_tree().create_timer(0.3 / fade_steps).timeout

	if is_instance_valid(mesh):
		mesh.material_overlay = null
		if free_after:
			mesh.queue_free()

func teleport_out_owner(tel_owner: Node3D, mesh: MeshInstance3D, teleport_mat: ShaderMaterial, duration: float = 2.0) -> void:
	if not is_instance_valid(tel_owner) or not is_instance_valid(mesh) or teleport_mat == null:
		return
	await teleport_out(mesh, teleport_mat, duration, false) # don't free mesh
	if is_instance_valid(tel_owner):
		tel_owner.queue_free()
		

func set_highlight(mesh: MeshInstance3D, outlined_mat: Material, state: bool) -> void:
	if not is_instance_valid(mesh):
		return
	mesh.material_override = outlined_mat if state and outlined_mat != null else null
