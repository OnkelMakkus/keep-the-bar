#playerAim.gd
extends Node
class_name PlayerAim

signal target_changed(new_target: Object)

@export var ray_front: RayCast3D        # $Head/RayCast3D_Front
@export var highlight_group := "Pickupable"
@export var debug_hits := false

@export var prompt_by_group := {
	"Pickupable": "<LMB> Pickup",
	"Bottle": "<LMB> Pickup • <RMB> pour",
	"Glass": "<LMB> Pickup • <RMB> pour",
	"Customer": "<LMB> Talk",
	"Recycler_Button": "<LMB> Recycle",
	"Replicator": "<LMB> Open Replicator",
	"Open_Schild": "<LMB> Open / Close Bar",
	"Order_Schild": "<LMB> TO INTERACT",
	"Theke": "Bar"
}

@export var prefer_group_prompt: bool = true
@export var allow_object_override: bool = false

var current_target: Object = null
var highlighted: Node3D = null

func _ready() -> void:
	if ray_front:
		ray_front.enabled = true
		# Falls du Areas treffen willst:
		ray_front.collide_with_areas = true


func _debug_trace_hit(n: Node) -> void:
	var i := 0
	while n and i < 8:
		print(i, ": ", n.name, "  groups=", n.get_groups())
		n = n.get_parent(); i += 1
		
		
func _physics_process(_dt: float) -> void:
	var hit: Object = null
	if ray_front and ray_front.is_colliding():
		hit = ray_front.get_collider()
		if debug_hits and hit is Node:
			print("Ray hit:", (hit as Node).name)

	if hit != current_target:
		current_target = hit
		target_changed.emit(current_target)
		
	_update_hover_info()

	_update_highlight()

func collider() -> Object:
	return current_target

func collision_point() -> Vector3:
	if ray_front and ray_front.is_colliding():
		return ray_front.get_collision_point()
	return Vector3.ZERO

func owner_in_group(group_name: String) -> Node:
	if current_target == null:
		return null
	return Gamemanager.find_owner_of_group(current_target, group_name)

func owner_in_any_group(groups: Array[String]) -> Node:
	if current_target == null:
		return null
	return Gamemanager.find_owner_in_any_group(current_target, groups)

func _update_highlight() -> void:
	var obj: Node3D = null
	if current_target:
		var grp_owner := Gamemanager.find_owner_of_group(current_target, highlight_group)
		obj = grp_owner as Node3D

	if obj:
		if highlighted and is_instance_valid(highlighted) and highlighted != obj:
			Gamemanager.highlight_object(highlighted, false)
		Gamemanager.highlight_object(obj, true)
		highlighted = obj
	elif highlighted:
		if is_instance_valid(highlighted):
			Gamemanager.highlight_object(highlighted, false)
		highlighted = null
		
		
func _update_hover_info() -> void:
	# nichts getroffen
	if current_target == null:
		Signalmanager.update_info_text_label.emit("")
		Signalmanager.update_info_label.emit("")
		return

	var hover_owner := _get_owner_for_hover()

	# 1) Objekttext bevorzugen (Detail)
	var detail := _get_object_label(hover_owner)
	if detail != "":
		Signalmanager.update_info_text_label.emit(detail)
		# Prompt nur als Fallback → leer lassen
		Signalmanager.update_info_label.emit("")
		return

	# 2) Kein Objekttext → Gruppen-Prompt als Fallback
	var prompt := _first_prompt_for(hover_owner)
	Signalmanager.update_info_text_label.emit("")   # kein Detail vorhanden
	Signalmanager.update_info_label.emit(prompt)


func _emit_detail_from_owner(o: Node) -> void:
	var txt: String = ""
	if o and o.has_method("label_text"):
		txt = str(o.label_text())
	elif o:
		var v: Variant = o.get("label_name") # null, wenn es das Feld nicht gibt
		if v != null and typeof(v) == TYPE_STRING:
			txt = String(v)
	Signalmanager.update_info_text_label.emit(txt)
	
	
# --- Helpers neu ---
func _get_owner_for_hover() -> Node:
	var group_list: Array[String] = []
	for k in prompt_by_group.keys():
		group_list.append(String(k))
	var grp_owner := Gamemanager.find_owner_in_any_group(current_target, group_list)
	if grp_owner == null:
		grp_owner = Gamemanager.find_owner_of_group(current_target, "Pickupable")
	return grp_owner

func _get_object_label(o: Node) -> String:
	if o == null:
		return ""
	if o.has_method("label_text"):
		return str(o.label_text())
	var v: Variant = o.get("label_name")
	if v != null and typeof(v) == TYPE_STRING:
		return String(v)
	return ""

func _first_prompt_for(grp_owner: Node) -> String:
	if grp_owner == null:
		return ""
	for k in prompt_by_group.keys():
		var g := String(k)
		if grp_owner.is_in_group(g):
			return String(prompt_by_group[g])
	return ""
