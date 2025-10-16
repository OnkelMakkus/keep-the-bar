#PlayerMovement.gd
extends Node

@export_group("Refs")
@export var player: CharacterBody3D
@export var head: Node3D
@export var camera: Camera3D
@export var raycast_down: RayCast3D
@export var flashlight: SpotLight3D

@export_group("Move")
@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 4.5
@export var gravity := 9.8
@export var mouse_sensitivity := 0.2

@export_group("Zero-G")
@export var fly_speed := 0.8
@export var air_damp := 18.0
@export var max_fly_speed := 6.0
@export var fly_vertical := 6.0
@export var zero_g_fov_delta := 5.0

var _mouse_captured := true
var _fov_tween: Tween
var _zero_g := false

func is_zero_g() -> bool:
	return _zero_g

func _ready() -> void:
	if flashlight:
		flashlight.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured and not Gamemanager.is_in_menu:
		player.rotation.y -= event.relative.x * mouse_sensitivity * 0.01
		head.rotation.x = clamp(head.rotation.x - event.relative.y * mouse_sensitivity * 0.01,
								deg_to_rad(-89), deg_to_rad(89))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not _mouse_captured and not Gamemanager.is_in_menu:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_captured = true
		Signalmanager.switch_menuBtn_visibility.emit(false)

	if event.is_action_pressed("Flashlight") and not Gamemanager.is_in_menu and flashlight:
		flashlight.visible = not flashlight.visible

func _physics_process(dt: float) -> void:
	_update_zero_g_state()
	if _zero_g:
		_move_zero_g(dt)
	else:
		_move_grounded(dt)

func _update_zero_g_state() -> void:
	var new_state := not (raycast_down and raycast_down.is_colliding())
	if new_state != _zero_g:
		_zero_g = new_state
		_tween_fov(_zero_g)

func _move_grounded(dt: float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= gravity * dt
	elif Input.is_action_just_pressed("jump") and not Gamemanager.is_in_menu:
		player.velocity.y = jump_velocity

	var dir := Vector3.ZERO
	var f := -player.global_transform.basis.z
	var r :=  player.global_transform.basis.x
	if not Gamemanager.is_in_menu:
		if Input.is_action_pressed("move_forward"): dir += f
		if Input.is_action_pressed("move_back"):    dir -= f
		if Input.is_action_pressed("move_right"):   dir += r
		if Input.is_action_pressed("move_left"):    dir -= r
	dir.y = 0
	dir = dir.normalized()

	var speed := move_speed
	if Input.is_action_pressed("sprint"):
		speed = sprint_speed

	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed
	player.move_and_slide()

func _move_zero_g(dt: float) -> void:
	player.velocity.y = 0.0
	var basis := player.global_transform.basis
	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"): dir += -basis.z
	if Input.is_action_pressed("move_back"):    dir +=  basis.z
	if Input.is_action_pressed("move_right"):   dir +=  basis.x
	if Input.is_action_pressed("move_left"):    dir += -basis.x

	var up_down := false
	if Input.is_action_pressed("jump"):
		dir += basis.y; up_down = true
	if Input.is_action_pressed("move_down"):
		dir += -basis.y; up_down = true

	dir = dir.normalized()
	var accel := fly_speed
	if up_down:
		accel = fly_vertical

	player.velocity += dir * accel
	player.velocity = player.velocity.limit_length(max_fly_speed)
	var damp := air_damp
	if up_down:
		damp = 1.0
	player.velocity = player.velocity.move_toward(Vector3.ZERO, damp * dt)
	player.move_and_slide()

func _tween_fov(enable_zero_g: bool) -> void:
	if _fov_tween:
		_fov_tween.kill()
	var base_fov := Gamemanager.FOV
	var target := base_fov
	if enable_zero_g:
		target = base_fov + zero_g_fov_delta
	_fov_tween = player.create_tween()
	_fov_tween.tween_property(camera, "fov", target, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func release_mouse_for_ui() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_mouse_captured = false
