#Player.gd
class_name Player
extends CharacterBody3D

@export var movement: Node        # PlayerMovement.gd
@export var aim: Node             # PlayerAim.gd
@export var interaction: Node     # PlayerInteraction.gd
@export var head: Node3D 
@export var camera: Camera3D 
@export var hand_slot: Node3D

signal target_changed(new_target)

func _ready() -> void:
	# Aim-Events an Player weiterreichen (UI kann nur Player kennen)
	aim.target_changed.connect(func(t):
		target_changed.emit(t)
	)

# -------- Public API (Fassade) --------
func current_target() -> Object:
	return aim.collider()

func current_hit_point() -> Vector3:
	return aim.collision_point()

func is_zero_g() -> bool:
	return movement.is_zero_g()

func pick_up(item: Node3D) -> void:
	interaction.pick_up(item)

func drop() -> void:
	interaction._on_drop_key()

func place_or_drop() -> void:
	interaction._place_or_free()

# Menü/Maus zentral schalten (UI ruft Player)
func set_menu_open(open: bool) -> void:
	Gamemanager.is_in_menu = open
	if open:
		movement.release_mouse_for_ui()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Optional: Zugriff auf „Held“
func get_held() -> Node3D:
	return interaction.held_object

func has_held() -> bool:
	return interaction.held_object != null
