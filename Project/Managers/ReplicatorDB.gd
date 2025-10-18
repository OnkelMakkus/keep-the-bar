# ReplicatorDB.gd
extends Node
signal mats_changed()

@export_dir var mats_dir  := "res://Project/Data/Mats"
@export_dir var items_dir := "res://Project/Data/Replicator"

var MATS:  Dictionary = {}   # id -> RepBaseMat
var ITEMS: Dictionary = {}   # id -> ReplicatorItem


func _ready() -> void:
	MATS.clear()
	ITEMS.clear()

	# Laden
	_load_all(mats_dir, func(r):
		if r is RepBaseMat and r.id != "":
			MATS[r.id] = r
	)
	_load_all(items_dir, func(r):
		if r is ReplicatorItem and r.id != "":
			# Falls Szene als Pfad gespeichert wurde, im Export explizit nachladen
			if "scene" in r and r.scene == null and "scene_path" in r and typeof(r.scene_path) == TYPE_STRING and r.scene_path != "":
				var ps := load(r.scene_path)
				if ps is PackedScene:
					r.scene = ps
			ITEMS[r.id] = r
	)

	# Kurzes Debug
	print("[ReplicatorDB] Loaded: MATS=%d  ITEMS=%d" % [MATS.size(), ITEMS.size()])
	for k in ITEMS.keys():
		var it: ReplicatorItem = ITEMS[k]
		print("  - item:", it.id, " scene_ok=", it.scene != null, " recycle_yield=", it.recycle_yield_factor)


# ============== Loader (export-sicher) ==============

func _load_all(root: String, on_res: Callable) -> void:
	var da := DirAccess.open(root)
	if da == null:
		print("[ReplicatorDB] DirAccess.open FAIL:", root)
		return
	print("[ReplicatorDB] Scan:", root)
	da.list_dir_begin()
	while true:
		var n := da.get_next()
		if n == "": break

		if da.current_is_dir():
			_load_all(root + "/" + n, on_res)
			continue

		var path := _normalize_res_path(root + "/" + n)
		if path == "":
			continue

		var res := ResourceLoader.load(path)
		if res == null:
			print("[ReplicatorDB] ⚠ load FAIL:", path, "(from:", n, ")")
			continue
		on_res.call(res)
	da.list_dir_end()


# .tres/.res (auch .remap) erlauben; alles andere ignorieren
func _normalize_res_path(p: String) -> String:
	if p.ends_with(".tres.remap") or p.ends_with(".res.remap"):
		return p.substr(0, p.length() - ".remap".length())
	if p.ends_with(".tres") or p.ends_with(".res"):
		return p
	return ""


# ============== Zugriff ==============

func get_item(id: String) -> ReplicatorItem:
	return ITEMS.get(id, null)

func get_mat(id: String) -> RepBaseMat:
	return MATS.get(id, null)

func all_items() -> Array:
	return ITEMS.values()

func all_mats() -> Array:
	return MATS.values()


# ============== Logik ==============

func can_afford(item_id: String) -> bool:
	var it := get_item(item_id)
	if it == null:
		return false
	for ma: RepMatAmount in it.cost:
		if ma == null or ma.mat == null:
			return false
		var base := get_mat(String(ma.mat.id))
		if base == null:
			return false
		if base.current_amount < ma.amount:
			return false
	return true


func item_cost_coins(item_id: String) -> int:
	var it := get_item(item_id)
	if it == null:
		return 0
	var sum := 0
	for ma: RepMatAmount in it.cost:
		if ma and ma.mat:
			sum += ma.amount * max(0, ma.mat.buy_price)
	return sum


func consume_cost(item_id: String) -> void:
	var it := get_item(item_id)
	if it == null:
		return
	for ma: RepMatAmount in it.cost:
		if ma == null or ma.mat == null:
			continue
		var base := get_mat(String(ma.mat.id))
		if base:
			base.current_amount = max(0, base.current_amount - ma.amount)
	emit_signal("mats_changed")


func credit_recycle(item_id: String) -> void:
	var it := get_item(item_id)
	if it == null:
		return
	for ma: RepMatAmount in it.cost:
		if ma == null or ma.mat == null:
			continue
		var base := get_mat(String(ma.mat.id))
		if base:
			var back := int(round(ma.amount * it.recycle_yield_factor))
			base.current_amount += back
	emit_signal("mats_changed")


# Optional kleine Helfer fürs HUD/Debug

func set_mat_amount(id: String, amount: int) -> void:
	var m := get_mat(id)
	if m:
		m.current_amount = max(0, amount)
		emit_signal("mats_changed")

func add_mat_amount(id: String, delta: int) -> void:
	set_mat_amount(id, (get_mat(id).current_amount if get_mat(id) else 0) + delta)
