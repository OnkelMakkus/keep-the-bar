# gamemanager.gd (global, neu)
extends Node

# ---------- Referenzen / Marker ----------
var spawnmarker: Marker3D
var thekemarker: Marker3D
var wait_marker_01: Marker3D
var wait_marker_02: Marker3D
var look_at_marker: Marker3D
var customer_exit: Marker3D
var first_exit: Marker3D
var serving_container: Node3D
var theke: Node

var main_ui: Control

# ---------- Zustände ----------
var theke_besetzt := false
var marker1_besetzt := false
var marker2_besetzt := false
var fullscreen := true
var is_in_menu := false
var is_open := false
var replicator_open := false
var option_open := false
var player_interaction: Node = null

var money: int = 100

# ---------- Sammlungen ----------
var ordermarkers: Array = []
var wait_markers: Array = []
var customers: Array[CharacterBody3D] = []

# ---------- Marker-Pools ----------
var abstell_marker: Array[Marker3D] = []
var serving_marker: Array[Marker3D] = []
var bottle_marker: Array[Marker3D] = []

# ---------- Optik ----------
@onready var mouse_sensitivity := 0.01
@export var FOV: int = 70

# ---------- Szenen ----------
const FORCE_INCLUDE := [
	preload("res://Project/Items/glass.tscn"),
	preload("res://Project/Items/beer_bottle.tscn"),
	preload("res://Project/Items/bottle_whisky.tscn"),
	preload("res://Project/Items/bottle_wodka.tscn"),
	preload("res://Project/Items/bottle_rum.tscn"),
]

@onready var og_scene: PackedScene = preload("res://Project/Helper/outline_generator.tscn")
@onready var ORDER_MENU: PackedScene = preload("res://Project/UI/order_menu.tscn")
@onready var OPTION_MENU: PackedScene = preload("res://Project/UI/options.tscn")
@onready var GLASS_SCENE: PackedScene = preload("res://Project/Items/glass.tscn")
@onready var BEER_SCENE: PackedScene = preload("res://Project/Items/beer_bottle.tscn")

# ---------- Kunden-Namen ----------
const CUSTOMER_MALE_NAMES = [
	"Kalle","Robin","Kevin","Murat","Sven","Dieter","Ragnar","Jax","Tobias","Enrico",
	"Zarnak","Threx","Bo","Gunther","Levik","Orion","Brax","Jens","Korben","Malik",
	"Rado","Xel","Yorr","T'Var","Vargo"
]
const CUSTOMER_FEMALE_NAMES = [
	"Ute","Jaqueline","Saskia","Yvonne","Uschi","Zara","Mira","Nayla","Chantal","Brigitte",
	"Velia","Kira","Synn","Eluna","Trixi","Ayra","Nova","Leena","Vexa","Nora",
	"T'Sari","Myxa","Rin","Xanna","Oona"
]

# ---------- Lebenszyklus ----------
func _ready() -> void:
	check_if_release()
	Signalmanager.set_spawn_marker.connect(setSpawn)
	Signalmanager.set_waiting_marker_01.connect(setWaiting01)
	Signalmanager.set_waiting_marker_02.connect(setWaiting02)
	Signalmanager.set_theke_marker.connect(setTheke)
	Signalmanager.set_look_at_marker.connect(setLookAt)
	Signalmanager.set_customer_exit.connect(setCustomerExit)
	Signalmanager.set_first_exit_marker.connect(setFirstExit)
	Signalmanager.add_customer.connect(add_customer)
	Signalmanager.remove_customer.connect(remove_customer)

# ---------- Fenster / FOV ----------
func check_if_release() -> void:
	if Engine.is_editor_hint():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		var screen := DisplayServer.window_get_current_screen()
		var size := DisplayServer.screen_get_size(screen)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
		_set_camera_fov(size)

func _set_camera_fov(screen_size: Vector2) -> void:
	const H_FOV_DESIRED := 100.0
	var V_FOV = rad_to_deg(2.0 * atan(tan(deg_to_rad(H_FOV_DESIRED) * 0.5) / (screen_size.x / screen_size.y)))
	var cam := get_node_or_null("Camera3D")
	if cam:
		cam.fov = V_FOV

# ---------- Kunden-Warteschlange ----------
func update_customers() -> void:
	wait_markers = [wait_marker_01, wait_marker_02]
	for i in customers.size():
		var cust: CharacterBody3D = customers[i]
		var target: Vector3
		if i == 0:
			target = thekemarker.global_position
		elif i - 1 < wait_markers.size():
			target = wait_markers[i - 1].global_position
		else:
			var steps = i - wait_markers.size() + 1
			target = wait_markers.back().global_position - Vector3(0, 0, 2.0 * steps)
		cust.set_queue_target(target)

func add_customer(cust: CharacterBody3D) -> void:
	customers.append(cust)
	update_customers()

func remove_customer(cust: CharacterBody3D) -> void:
	customers.erase(cust)
	update_customers()

# ---------- Marker-Setzer ----------
func setSpawn(spawn: Marker3D) -> void:
	spawnmarker = spawn

func setTheke(theke_obj: Marker3D) -> void:
	thekemarker = theke_obj
	ordermarkers.push_back(thekemarker)
	theke = thekemarker.get_parent()

func setWaiting01(wait_obj: Marker3D) -> void:
	wait_marker_01 = wait_obj
	ordermarkers.push_back(wait_marker_01)

func setWaiting02(wait_obj: Marker3D) -> void:
	wait_marker_02 = wait_obj
	ordermarkers.push_back(wait_marker_02)

func setLookAt(lookAt_obj: Marker3D) -> void:
	look_at_marker = lookAt_obj

func setCustomerExit(exit: Marker3D) -> void:
	customer_exit = exit

func setFirstExit(first_exit_marker_: Marker3D) -> void:
	first_exit = first_exit_marker_
	
func get_nearest_free_marker(markers: Array[Marker3D], ref: Vector3) -> Marker3D:
	var best: Marker3D = null
	var best_d := INF
	for m in markers:
		if not is_instance_valid(m): continue
		if m.get_child_count() > 0: continue
		if m.get_meta("occupied", false): continue
		var d := ref.distance_to(m.global_position)
		if d < best_d:
			best_d = d
			best = m
	return best

func place_on_marker(obj: Node3D, m: Marker3D) -> bool:
	if obj == null or not is_instance_valid(obj) or m == null: return false
	# aus Hand/Welt lösen
	if obj.get_parent(): obj.get_parent().remove_child(obj)
	m.add_child(obj)
	obj.global_transform = Transform3D.IDENTITY
	obj.global_position = m.global_position
	# Physik wieder aktivieren
	unfreeze_after_place(obj)
	# Marker belegen und am Objekt referenzieren (damit wir später freigeben können)
	m.set_meta("occupied", true)
	obj.set_meta("__marker", m)
	return true

func place_on_best_marker(obj: Node3D, kind: String, ref: Vector3) -> bool:
	var pool: Array[Marker3D] = []
	match kind:
		"serving":
			pool = serving_marker
		"bottle":
			pool = bottle_marker
		"abstell":
			pool = abstell_marker
		_:
			pool = abstell_marker

	var m := get_nearest_free_marker(pool, ref)
	if m == null: return false

	var ok := place_on_marker(obj, m)
	if not ok: return false

	# 👇 wichtig für's Gießen:
	if kind == "serving":
		obj.set_meta("on_theke", true)
	else:
		if obj.has_meta("on_theke"):
			obj.remove_meta("on_theke")

	return true


# ---------- Helpers: Knoten finden ----------
func get_player(): return get_tree().get_first_node_in_group("Player")
func get_object(group): return get_tree().get_first_node_in_group(group)
func get_objects(group): return get_tree().get_nodes_in_group(group)

func find_owner_of_group(node_obj: Object, group_name: String, max_hops: int = 12) -> Node:
	var n := node_obj as Node
	var hops := 0
	while n and hops < max_hops:
		if n.is_in_group(group_name):
			return n
		if n.has_method("show_besitzer"):
			var b = n.show_besitzer()
			if b and b is Node:
				var owner_node := b as Node
				if owner_node.is_in_group(group_name):
					return owner_node
				n = owner_node; hops += 1; continue
		n = n.get_parent(); hops += 1
	return null

func find_owner_in_any_group(node_obj: Object, groups, max_hops: int = 12) -> Node:
	for g in groups:
		var r := find_owner_of_group(node_obj, String(g), max_hops)
		if r: return r
	return null

# ---------- Highlight ----------
func highlight_object(obj: Node3D, state: bool):
	if obj and is_instance_valid(obj) and obj.has_method("set_highlight"):
		obj.set_highlight(state)

func attach_outlineGenerator(to: Node3D) -> void:
	if to.has_node("OutlineGenerator"):
		return
	var outline_generator = og_scene.instantiate()
	outline_generator.name = "OutlineGenerator"
	to.add_child(outline_generator)
	outline_generator.set_highlight(false)

# ---------- Platzieren / Regal ----------
func place_on_shelf(obj: Node3D, reference_point: Vector3, shelf: Node3D) -> bool:
	var slots = shelf.get_children().filter(func(n): return n is Marker3D and not n.has_meta("belegt"))
	if slots.size() == 0: return false
	var closest: Marker3D = slots[0]
	var min_dist := reference_point.distance_to(closest.global_position)
	for s in slots:
		var dist = reference_point.distance_to(s.global_position)
		if dist < min_dist:
			closest = s; min_dist = dist
	obj.get_parent().remove_child(obj)
	shelf.add_child(obj)
	obj.global_position = closest.global_position
	obj.rotation = Vector3.ZERO
	closest.set_meta("belegt", true)
	return true

func get_mesh_sizes(mesh_instance: MeshInstance3D) -> Vector3:
	var mesh = mesh_instance.mesh
	if mesh:
		var aabb = mesh.get_aabb()
		var world_scale = mesh_instance.global_transform.basis.get_scale()
		return Vector3(aabb.size.x * world_scale.x, aabb.size.y * world_scale.y, aabb.size.z * world_scale.z)
	return Vector3.ZERO

# ---------- RigidBody-Freeze ----------
func _get_first_rigidbody(n: Node) -> RigidBody3D:
	if n is RigidBody3D: return n
	for c in n.get_children():
		var rb := _get_first_rigidbody(c)
		if rb: return rb
	return null

func freeze_for_pickup(obj: Node) -> void:
	var rb := _get_first_rigidbody(obj)
	if rb == null: return
	obj.set_meta("__rb_backup", {
		"freeze": rb.freeze,
		"gravity_scale": rb.gravity_scale,
		"layer": rb.collision_layer,
		"mask": rb.collision_mask
	})
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.gravity_scale = 0.0
	rb.freeze = true
	rb.collision_layer = 0
	rb.collision_mask = 0

func unfreeze_after_place(obj: Node) -> void:
	var rb := _get_first_rigidbody(obj)
	if rb == null: return
	var b = null
	if obj.has_meta("__rb_backup"):
		b = obj.get_meta("__rb_backup")
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.freeze = false
	rb.gravity_scale = (b["gravity_scale"] if b and "gravity_scale" in b else 1.0)
	rb.collision_layer = (b["layer"] if b and "layer" in b else 1)
	rb.collision_mask = (b["mask"] if b and "mask" in b else 1)
	if obj.has_meta("__rb_backup"):
		obj.remove_meta("__rb_backup")

# ---------- Placeable Flächen ----------
func is_placeable_surface(node_obj: Object) -> bool:
	return find_owner_of_group(node_obj, "placeable_surface") != null

func get_placeable_surface_owner(node_obj: Object) -> Node:
	return find_owner_of_group(node_obj, "placeable_surface")

# ==========================================================
# Serve / Recipes (Resources)
# ==========================================================

const MAX_MARKER_INDEX := 4  # Anzahl Slots pro Tisch (Index 1..N)

# Zentraler Serve-Versuch: Customer + Objekt (Glass/Bottle) prüfen.
# Rückgabe: { ok: bool, reason: String, price: int, place: Dictionary }
func attempt_serve(customer: Node, obj: Node) -> Dictionary:
	var result := {"ok": false, "reason": "", "price": 0, "place": {}}
	print("[serve] order=", customer and customer.order_text, " obj=", obj, " groups=", obj and obj.get_groups())

	if customer == null or obj == null:
		result.reason = "invalid_args"; return result

	var order_id := ""
	if "order_text" in customer:
		order_id = str(customer.order_text)
	var recipe: DrinkRecipe = DrinkDB.get_recipe_by_id(order_id)
	if recipe == null:
		result.reason = "unknown_order:" + order_id; return result

	var is_glass := obj.is_in_group("Glass")
	var is_bottle := obj.is_in_group("Bottle") or obj.is_in_group("BeerBottle")

	# Container-Anforderung
	if recipe.container == DrinkRecipe.RecipeContainer.GLASS and not is_glass:
		result.reason = "needs_glass"; return result
	if recipe.container == DrinkRecipe.RecipeContainer.BOTTLE and not is_bottle:
		result.reason = "needs_bottle"; return result
	
	print("[serve] container ok. bottle=", is_bottle, " glass=", is_glass)

	var ok := false
	if is_bottle:
		ok = _fits_bottle(obj, recipe)
		print("[serve] fits_bottle=", ok)
	elif is_glass:
		ok = _fits_glass(obj, recipe)
		print("[serve] fits_glass=", ok)
	else:
		result.reason = "unsupported_container"; return result

	if not ok:
		print("[serve] mismatch reason; recipe=", recipe.id)
		result.reason = "mismatch"; return result

	#Erfolg
	result.ok = true
	result.price = int(recipe.sell_price)
	Signalmanager.update_money.emit(result.price)

	# 🔒 Das tatsächlich servierte Objekt sofort entsorgen,
	# damit keine Interaktion/„Doppelhaltung“ mehr möglich ist.
	if is_instance_valid(obj):
		# optional: Parent lösen (nicht zwingend)
		# if obj.get_parent(): obj.get_parent().remove_child(obj)
		obj.queue_free()

	# Tischplatz reservieren (gleichindexig, tischübergreifend)
	result.place = find_free_indexed_place()
	return result
	
	
func _latest_serving_item_from_player() -> Node3D:
	if serving_container == null:
		return null
	var best: Node3D = null
	var best_ts := -1
	for c in serving_container.get_children():
		if c is Node3D and c.has_meta("__from_player"):
			var ts := int(c.get_meta("__drop_time", 0))
			if ts > best_ts:
				best_ts = ts
				best = c
	return best

# --- Bottle ↔ Recipe ---
func _fits_bottle(bottle: Node, recipe: DrinkRecipe) -> bool:
	if recipe.ingredients.size() != 1: return false
	var ing: IngredientAmount = recipe.ingredients[0]
	if ing == null or ing.liquid == null: return false
	if not ("liquid" in bottle and "volume_ml" in bottle): return false

	var b_liq: Liquid = bottle.liquid
	var b_vol: float = float(bottle.volume_ml)
	if b_liq == null: return false

	# WICHTIG: per ID vergleichen
	if b_liq.id != ing.liquid.id: return false

	return b_vol >= float(ing.amount_ml - recipe.ml_tolerance)


# --- Glass ↔ Recipe ---
func _fits_glass(glass: Node, recipe: DrinkRecipe) -> bool:
	# Jede Zutat prüfen
	for ing: IngredientAmount in recipe.ingredients:
		if ing == null or ing.liquid == null: return false

		var need_ml := int(ing.amount_ml - recipe.ml_tolerance)
		var have_ml := 0

		# Nutze die neue Glas-API per ID, damit es *immer* passt
		if glass.has_method("get_ml_by_id"):
			have_ml = int(glass.get_ml_by_id(ing.liquid.id))
		elif glass.has_method("get_ml"):
			# Fallback falls du get_ml(liquid) behalten willst
			have_ml = int(glass.get_ml(ing.liquid))
		else:
			return false

		if have_ml < need_ml:
			return false

	# Fremdstoffe sperren, falls nicht erlaubt
	if not recipe.allow_extras:
		# lies direkt die IDs aus contents
		var allowed: Dictionary = {}
		for ing2: IngredientAmount in recipe.ingredients:
			allowed[ing2.liquid.id] = true

		var cont = glass.get("contents") if glass else {}
		for lid in cont.keys():
			if not allowed.has(String(lid)):
				return false

	return true


# ==========================================================
# Tischplatz (Index-Paar)
# ==========================================================

# Holt auf einem Tisch anhand Index i:
# - standing_marker%02d
# - glass_marker%02d ODER glas_marker%02d (tolerant)
func _get_index_markers(t: Node, i: int) -> Array:
	var s = t.get("standing_marker%02d" % i)
	var g = null
	if t.has_method("get"): # Nodes haben get()
		g = t.get("glass_marker%02d" % i)
		if g == null:
			g = t.get("glas_marker%02d" % i)  # Fallback auf „glas“
	return [s, g]

func _is_free_marker(m: Node) -> bool:
	return m != null \
		and is_instance_valid(m) \
		and m is Marker3D \
		and m.get_child_count() == 0 \
		and not m.get_meta("reserved", false)

# Sucht tischübergreifend das erste freie gleichindexige Paar und reserviert
func find_free_indexed_place() -> Dictionary:
	var tables := get_tree().get_nodes_in_group("Table")
	for i in range(1, MAX_MARKER_INDEX + 1):
		for t in tables:
			var pair := _get_index_markers(t, i)
			var s: Marker3D = pair[0]
			var g: Marker3D = pair[1]
			if _is_free_marker(s) and _is_free_marker(g):
				s.set_meta("reserved", true)
				g.set_meta("reserved", true)
				return {
					"table": t,
					"index": i,
					"standing_marker": s,
					"glass_marker": g
				}
	return {}

# Reservierung wieder lösen (nach Platzierung)
func clear_place_reservation(pair: Dictionary) -> void:
	for k in ["standing_marker", "glass_marker", "glas_marker"]:
		if pair.has(k) and pair[k] and pair[k].has_meta("reserved"):
			pair[k].remove_meta("reserved")
