#DrinkDB.gd
extends Node

@export_dir var liquids_dir := "res://Project/Data/Liquids"
@export_dir var drinks_dir  := "res://Project/Data/Drinks"

var LIQUIDS: Dictionary = {}   # id -> Liquid
var DRINKS:  Dictionary = {}   # id -> DrinkRecipe

func _ready() -> void:
	LIQUIDS.clear()
	DRINKS.clear()
	_load_all(liquids_dir, func(r):
		if r is Liquid and r.id != "": LIQUIDS[r.id] = r)
	_load_all(drinks_dir, func(r):
		if r is DrinkRecipe and r.id != "": DRINKS[r.id] = r)
	print("[DrinkDB] Loaded: LIQUIDS=%d DRINKS=%d" % [LIQUIDS.size(), DRINKS.size()])

func _load_all(root: String, on_res: Callable) -> void:
	var da := DirAccess.open(root)
	if da == null:
		print("[DrinkDB] DirAccess.open FAIL:", root)
		return
	print("[DrinkDB] Scanne:", root)
	da.list_dir_begin()
	while true:
		var n := da.get_next()
		if n == "": break

		if da.current_is_dir():
			_load_all(root + "/" + n, on_res)
			continue

		var load_path := _normalize_res_path(root + "/" + n)
		if load_path == "": 
			continue

		var r := ResourceLoader.load(load_path)
		if r == null:
			print("[DrinkDB] ⚠️ load FAIL:", load_path, "(from:", n, ")")
			continue
		on_res.call(r)
	da.list_dir_end()

func _normalize_res_path(p: String) -> String:
	# Nur .tres / .res (mit optionalem .remap) zulassen
	if p.ends_with(".tres.remap"):
		return p.substr(0, p.length() - ".remap".length())
	if p.ends_with(".res.remap"):
		return p.substr(0, p.length() - ".remap".length())
	if p.ends_with(".tres") or p.ends_with(".res"):
		return p
	# Alles andere (z. B. .gdc, .gd.remap, .import) ignorieren
	return ""
	
func get_liquid(id: String) -> Liquid: return LIQUIDS.get(id, null)
func get_recipe_by_id(id: String) -> DrinkRecipe: return DRINKS.get(id, null)
