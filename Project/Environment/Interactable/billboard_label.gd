# billboard_label.gd
extends Label3D

@export var offset_y: float = 0.0
@export var offset_dist: float = 0.0   # optional, z.B. für Flasche: vor das Objekt setzen
@export var use_parent_rotation_compensation: bool = true
@export var use_position_at_parent := true

func _ready() -> void:
	if use_position_at_parent:
		offset_y = 0.0
		offset_dist = 0.0


func _process(_delta):
	var dir_to_cam : Vector3
	if not visible:
		return
		
	var cam = get_viewport().get_camera_3d()
	if cam:
		var parent = get_parent()
		var cam_pos = cam.global_transform.origin
		var my_pos = global_transform.origin
		# Optionaler Y-Offset (Höhe)
		my_pos.y += offset_y

		# Optionaler Distanz-Offset (z.B. für Flasche)
		if offset_dist != 0.0:			
			if parent:
				dir_to_cam = (cam_pos - parent.global_transform.origin).normalized()
				my_pos = parent.global_transform.origin + dir_to_cam * offset_dist
				my_pos.y += offset_y
		global_transform.origin = my_pos

		# Blickrichtung nur auf Y-Achse
		cam_pos.y = my_pos.y
		dir_to_cam = (cam_pos - my_pos).normalized()
		var angle_y = atan2(dir_to_cam.x, dir_to_cam.z)
			
		# Parent-Rotation kompensieren, falls nötig
		var parent_angle = 0.0
		if use_parent_rotation_compensation and get_parent():
			parent_angle = get_parent().global_rotation.y

		if parent.get_parent().is_in_group("Regalbrett"):
			# Regal: Rotations-Offset explizit setzen
			rotation = Vector3(0, angle_y - parent_angle - deg_to_rad(90), 0)
		else:
			rotation = Vector3(0, angle_y - parent_angle, 0)
