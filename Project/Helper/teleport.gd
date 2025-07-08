extends Node3D
## Einfache Lichtsäule, wächst aus dem Boden, schrumpft zurück
## und ruft optional eine Spawn-Callback auf, wenn sie oben ist.

@export var mesh: MeshInstance3D

# Inspector-Parameter
@export var color            : Color  = Color(0.3, 0.8, 1.0)
@export var emission         : float  = 8.0
@export var radius           : float  = 0.35
@export var duration_up      : float  = 0.5
@export var duration_down    : float  = 0.5
@export var height_factor    : float  = 1.2      # 20 % Spielraum oberhalb Ziel-Höhe

var internal_target
var internal_despawn_target
# interner Tween
var _tw : Tween

## Haupt-Aufruf -----------------------------------------------------------------
## Übergib den Transform oder Knoten, an dessen Stelle gespawnt wird.
func start(target, max_scale: Vector3, despawn_target, despawn := false):
	internal_target = target
	internal_despawn_target = despawn_target
	internal_target.visible = false
	# Material kopieren & einfärben
	var mat = mesh.get_active_material(0).duplicate()
	mat.albedo_color    = color
	mat.emission        = color
	mat.emission_energy = emission
	mesh.material_override = mat
	
	var full_scale  := Vector3(radius, max_scale.y, radius)
	
	# Startzustand: aus Boden (y=0)
	mesh.scale = Vector3(radius, 0.0, radius)
	mesh.visible = true
	
	# Tween: rauf
	_tw = create_tween()
	_tw.tween_property(mesh, "scale", full_scale, duration_up).set_trans(Tween.TRANS_SINE)
	if not despawn:
		_tw.tween_callback(_spawn_target)                # Peak erreicht
	
	# Tween: wieder runter
	_tw.tween_property(mesh, "scale", Vector3(radius, 0, radius), duration_down).set_trans(Tween.TRANS_SINE)
	_tw.tween_callback(_make_invisible)	
	if despawn:
		_tw.tween_callback(_despawn_target)   

## ---------------------------------------------------------------------------
func _make_invisible():
	mesh.visible = false


func _spawn_target():
	internal_target.visible = true
	
	
func _despawn_target():
	internal_despawn_target.queue_free()
