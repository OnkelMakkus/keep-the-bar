@tool
extends VBoxContainer

# ─────────────────────────────
# Editor / Pfade / Klassen
# ─────────────────────────────
var editor_interface: EditorInterface

const PATH_SCENES_ITEMS = "res://Project/Items"  # falls deine .tscn dort liegen
const PATH_MATS     = "res://Project/Data/Mats"
const PATH_LIQUIDS  = "res://Project/Data/Liquids"
const PATH_ITEMS    = "res://Project/Data/Replicator"
const PATH_DRINKS   = "res://Project/Data/Drinks"

var RepBaseMat       = preload("res://Project/Data/Mats/rep_base_mat.gd")
var Liquid           = preload("res://Project/Data/Liquids/liquid.gd")
var ReplicatorItem   = preload("res://Project/Data/Replicator/replicator_item.gd")
var DrinkRecipe      = preload("res://Project/Data/Drinks/drink_recipe.gd")
var IngredientAmount = preload("res://Project/Data/Drinks/ingredient_amount.gd")

# ─────────────────────────────
# Dialoge / Caches / State
# ─────────────────────────────
var _efd: EditorFileDialog            # Resource-Picker (LiquidsTab)
var _scene_dialog: EditorFileDialog   # Scene-Picker (ItemsTab)
var _load_dialog: EditorFileDialog    # Loader (alle Tabs)
var _load_target: String = ""         # "mat" | "liquid" | "item" | "drink"

var _liquids_cache: Dictionary = {}   # id -> Liquid
var _pending_ingredients: Array[IngredientAmount] = []

# ─────────────────────────────
# Exports: MATS TAB
# ─────────────────────────────
@export_group("Mats")
@export var mat_id_input: LineEdit
@export var mat_name_input: LineEdit
@export var mat_unit_input: LineEdit
@export var mat_price_input: SpinBox
@export var mat_amount_input: SpinBox
@export var mat_save_btn: Button
@export var mat_open_btn: Button
@export var mat_clear_btn: Button
@export var mat_tier_input: SpinBox
@export var mat_unlock_cost_input: SpinBox
@export var mat_unlocked_input: CheckBox
@export var mat_prereq_input: LineEdit
@export var mat_tags_input: LineEdit

# ─────────────────────────────
# Exports: LIQUIDS TAB
# ─────────────────────────────
@export_group("Liquids")
@export var liquid_id_input: LineEdit
@export var liquid_name_input: LineEdit
@export var liquid_mat_picker_btn: Button
@export var liquid_mat_path: LineEdit
@export var liquid_save_btn: Button
@export var liquid_open_btn: Button
@export var liquid_clear_btn: Button
@export var liquid_tier_input: SpinBox
@export var liquid_unlock_cost_input: SpinBox
@export var liquid_unlocked_input: CheckBox
@export var liquid_prereq_input: LineEdit
@export var liquid_tags_input: LineEdit

# ─────────────────────────────
# Exports: ITEMS TAB
# ─────────────────────────────
@export_group("Items")
@export var item_id_input: LineEdit
@export var item_name_input: LineEdit
@export var item_scene_path: LineEdit
@export var item_scene_pick: Button
@export var item_liquid_input: LineEdit
@export var item_ml_input: SpinBox
@export var item_save_btn: Button
@export var item_open_btn: Button
@export var item_clear_btn: Button
@export var item_tier_input: SpinBox
@export var item_unlock_cost_input: SpinBox
@export var item_unlocked_input: CheckBox
@export var item_prereq_input: LineEdit
@export var item_tags_input: LineEdit

# ─────────────────────────────
# Exports: DRINKS TAB
# ─────────────────────────────
@export_group("Drinks")
@export var drink_id_input: LineEdit
@export var drink_name_input: LineEdit
@export var drink_price_input: SpinBox
@export var drink_container_input: OptionButton
@export var drink_spoil_input: SpinBox
@export var drink_save_btn: Button
@export var ingredient_liquid_select: OptionButton
@export var ingredient_amount_input: SpinBox
@export var ingredient_add_btn: Button
@export var ingredient_list: VBoxContainer
@export var drink_open_btn: Button
@export var drink_clear_btn: Button
@export var drink_tier_input: SpinBox
@export var drink_unlock_cost_input: SpinBox
@export var drink_unlocked_input: CheckBox
@export var drink_prereq_input: LineEdit
@export var drink_tags_input: LineEdit

# ─────────────────────────────
# READY / Verkabelung
# ─────────────────────────────
func _ready():
	print("🧩 BarResourcePanel ready (export mode)")

	# Open/Load	
	if mat_open_btn:    mat_open_btn.pressed.connect(func(): _open_load_dialog("mat"))
	if liquid_open_btn: liquid_open_btn.pressed.connect(func(): _open_load_dialog("liquid"))
	if item_open_btn:   item_open_btn.pressed.connect(func(): _open_load_dialog("item"))
	if drink_open_btn:  drink_open_btn.pressed.connect(func(): _open_load_dialog("drink"))

	#Clear
	if mat_clear_btn:    mat_clear_btn.pressed.connect(_clear_mat)
	if liquid_clear_btn: liquid_clear_btn.pressed.connect(_clear_liquid)
	if item_clear_btn:   item_clear_btn.pressed.connect(_clear_item)
	if drink_clear_btn:  drink_clear_btn.pressed.connect(_clear_drink)
	
	# Save
	if mat_save_btn:     mat_save_btn.pressed.connect(_save_mat)
	if liquid_save_btn:  liquid_save_btn.pressed.connect(_save_liquid)
	if item_save_btn:    item_save_btn.pressed.connect(_save_item)
	if drink_save_btn:   drink_save_btn.pressed.connect(_save_drink)

	# Picker
	if liquid_mat_picker_btn: liquid_mat_picker_btn.pressed.connect(_open_editor_file_dialog)
	if item_scene_pick:       item_scene_pick.pressed.connect(_open_scene_dialog)

	# Drinks: Add Ingredient
	if ingredient_add_btn: ingredient_add_btn.pressed.connect(_on_add_ingredient)

	# Drinks: Container-Enum anlegen (muss zu RecipeContainer passen)
	if drink_container_input and drink_container_input.item_count == 0:
		drink_container_input.add_item("ANY")    # 0
		drink_container_input.add_item("GLASS")  # 1
		drink_container_input.add_item("BOTTLE") # 2
		drink_container_input.selected = 0

	# Defaults
	if ingredient_amount_input:
		ingredient_amount_input.min_value = 0
		ingredient_amount_input.max_value = 2000
		ingredient_amount_input.step = 5

	# Daten
	_load_liquids()

# ─────────────────────────────
# LOAD: Liquids in Dropdown
# ─────────────────────────────
func _load_liquids():
	_liquids_cache.clear()
	if ingredient_liquid_select:
		ingredient_liquid_select.clear()

	var dir := DirAccess.open(PATH_LIQUIDS)
	if dir:
		dir.list_dir_begin()
		while true:
			var f := dir.get_next()
			if f == "": break
			if dir.current_is_dir(): continue
			if f.ends_with(".tres") or f.ends_with(".res"):
				var p := "%s/%s" % [PATH_LIQUIDS, f]
				var liquid_res := load(p)
				if liquid_res is Liquid:
					_liquids_cache[liquid_res.id] = liquid_res
					if ingredient_liquid_select:
						ingredient_liquid_select.add_item(liquid_res.display_name) # ids = index
		dir.list_dir_end()

# ─────────────────────────────
# DRINKS: Ingredients hinzufügen
# ─────────────────────────────
func _on_add_ingredient():
	if not ingredient_liquid_select: return
	var index := ingredient_liquid_select.selected
	if index < 0: return
	var name := ingredient_liquid_select.get_item_text(index)

	var liquid: Liquid = _find_liquid_by_display(name)
	if liquid == null: return

	var amount := int(ingredient_amount_input.value if ingredient_amount_input else 0)
	var ing := IngredientAmount.new()
	ing.liquid = liquid
	ing.amount_ml = amount
	_pending_ingredients.append(ing)
	_add_ingredient_row_ui(liquid, amount)

func _find_liquid_by_display(name: String) -> Liquid:
	for id in _liquids_cache:
		var l: Liquid = _liquids_cache[id]
		if l.display_name == name:
			return l
	return null

func _add_ingredient_row_ui(liquid: Liquid, amount: int) -> void:
	if ingredient_list == null: return
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "%s – %d ml" % [liquid.display_name, amount]

	var del := Button.new()
	del.text = "✖"
	del.focus_mode = Control.FOCUS_NONE

	var on_delete := func():
		for i in range(_pending_ingredients.size()):
			var it := _pending_ingredients[i]
			if it.liquid == liquid and it.amount_ml == amount:
				_pending_ingredients.remove_at(i)
				break
		row.queue_free()

	del.pressed.connect(on_delete)

	row.add_child(lbl)
	row.add_child(del)
	ingredient_list.add_child(row)

# ─────────────────────────────
# COMMON: File-Open Dialoge
# ─────────────────────────────
func _open_editor_file_dialog():
	if _efd == null:
		_efd = EditorFileDialog.new()
		_efd.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_efd.access = EditorFileDialog.ACCESS_RESOURCES
		_efd.add_filter("*.tres, *.res ; Resources")
		add_child(_efd)
		_efd.file_selected.connect(_on_editor_file_selected)
	_efd.popup_centered_ratio(0.8)

func _on_editor_file_selected(path: String) -> void:
	if liquid_mat_path:
		liquid_mat_path.text = path
	print("Selected resource:", path)

func _open_scene_dialog():
	if _scene_dialog == null:
		_scene_dialog = EditorFileDialog.new()
		_scene_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_scene_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_scene_dialog.add_filter("*.tscn ; Scenes")
		_scene_dialog.add_filter("*.scn  ; Scenes (legacy)")
		add_child(_scene_dialog)
		_scene_dialog.file_selected.connect(_on_scene_selected)

	# Erst zu vorhandenem Pfad, sonst Standard-Scenes-Ordner
	if item_scene_path and item_scene_path.text != "":
		_safe_set_path(_scene_dialog, item_scene_path.text)
	else:
		_safe_set_dir(_scene_dialog, PATH_ITEMS)

	_scene_dialog.popup_centered_ratio(0.8)

func _on_scene_selected(path: String) -> void:
	var res := load(path)
	if res is PackedScene and item_scene_path:
		item_scene_path.text = path
		print("✅ Scene gewählt:", path)
	else:
		push_warning("Ausgewählte Datei ist keine Scene: %s" % path)

# ─────────────────────────────
# COMMON: Loader (bestehende .tres öffnen)
# ─────────────────────────────
func _open_load_dialog(target: String):
	_load_target = target
	if _load_dialog == null:
		_load_dialog = EditorFileDialog.new()
		_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_load_dialog.add_filter("*.tres ; Resources")
		_load_dialog.add_filter("*.res  ; Binary Resources")
		add_child(_load_dialog)
		_load_dialog.file_selected.connect(_on_load_selected)

	# Startordner gemäß Tab
	match target:
		"mat":    _safe_set_dir(_load_dialog, PATH_MATS)
		"liquid": _safe_set_dir(_load_dialog, PATH_LIQUIDS)
		"item":   _safe_set_dir(_load_dialog, PATH_ITEMS)
		"drink":  _safe_set_dir(_load_dialog, PATH_DRINKS)

	# Wenn im Tab schon ein Pfad steht, dorthin springen
	if target == "item" and item_scene_path and item_scene_path.text != "":
		_safe_set_path(_load_dialog, item_scene_path.text)
	elif target == "liquid" and liquid_mat_path and liquid_mat_path.text != "":
		_safe_set_path(_load_dialog, liquid_mat_path.text)

	_load_dialog.popup_centered_ratio(0.8)

func _on_load_selected(path: String) -> void:
	var res := load(path)
	if res == null:
		push_warning("Konnte Resource nicht laden: %s" % path)
		return

	match _load_target:
		"mat":
			if res is RepBaseMat:
				_apply_mat(res)
			else:
				push_warning("Kein RepBaseMat: %s" % path)
		"liquid":
			if res is Liquid:
				_apply_liquid(res)
			else:
				push_warning("Kein Liquid: %s" % path)
		"item":
			if res is ReplicatorItem:
				_apply_item(res)
			else:
				push_warning("Kein ReplicatorItem: %s" % path)
		"drink":
			if res is DrinkRecipe:
				_apply_drink(res)
			else:
				push_warning("Kein DrinkRecipe: %s" % path)

# ─────────────────────────────
# APPLY / CLEAR pro Tab
# ─────────────────────────────
func _apply_mat(m: RepBaseMat) -> void:
	if mat_id_input:     mat_id_input.text   = m.id
	if mat_name_input:   mat_name_input.text = m.display_name
	if mat_unit_input:   mat_unit_input.text = m.unit
	if mat_price_input:  mat_price_input.value  = m.buy_price
	if mat_amount_input: mat_amount_input.value = m.buy_amount
	if mat_tier_input:         mat_tier_input.value = m.tier
	if mat_unlock_cost_input:  mat_unlock_cost_input.value = m.unlock_cost
	if mat_unlocked_input:     mat_unlocked_input.button_pressed = m.unlocked_by_default
	if mat_prereq_input:       mat_prereq_input.text = _join_csv(m.prerequisites)
	if mat_tags_input:         mat_tags_input.text = _join_csv(m.tags)


func _apply_liquid(l: Liquid) -> void:
	if liquid_id_input:    liquid_id_input.text    = l.id
	if liquid_name_input:  liquid_name_input.text  = l.display_name
	# if liquid_mat_path and l.material: liquid_mat_path.text = l.material.resource_path
	if liquid_tier_input:         liquid_tier_input.value = l.tier
	if liquid_unlock_cost_input:  liquid_unlock_cost_input.value = l.unlock_cost
	if liquid_unlocked_input:     liquid_unlocked_input.button_pressed = l.unlocked_by_default
	if liquid_prereq_input:       liquid_prereq_input.text = _join_csv(l.prerequisites)
	if liquid_tags_input:         liquid_tags_input.text = _join_csv(l.tags)


func _apply_item(i: ReplicatorItem) -> void:
	if item_id_input:     item_id_input.text   = i.id
	if item_name_input:   item_name_input.text = i.display_name
	if item_scene_path and i.scene: item_scene_path.text = i.scene.resource_path
	if item_liquid_input and i.default_liquid: item_liquid_input.text = i.default_liquid.id
	if item_ml_input:     item_ml_input.value  = i.default_ml
	# Unlock-Felder:
	if item_tier_input:         item_tier_input.value = i.tier
	if item_unlock_cost_input:  item_unlock_cost_input.value = i.unlock_cost
	if item_unlocked_input:     item_unlocked_input.button_pressed = i.unlocked_by_default
	if item_prereq_input:       item_prereq_input.text = _join_csv(i.prerequisites)
	if item_tags_input:         item_tags_input.text = _join_csv(i.tags)


func _apply_drink(d: DrinkRecipe) -> void:
	if drink_id_input:    drink_id_input.text = d.id
	if drink_name_input:  drink_name_input.text = d.display_name
	if drink_price_input: drink_price_input.value = d.sell_price
	if drink_spoil_input: drink_spoil_input.value = d.spoil_time
	if drink_container_input and d.container >= 0 and d.container < drink_container_input.item_count:
		drink_container_input.selected = d.container

	# Unlock-Felder:
	if drink_tier_input:         drink_tier_input.value = d.tier
	if drink_unlock_cost_input:  drink_unlock_cost_input.value = d.unlock_cost
	if drink_unlocked_input:     drink_unlocked_input.button_pressed = d.unlocked_by_default
	if drink_prereq_input:       drink_prereq_input.text = _join_csv(d.prerequisites)
	if drink_tags_input:         drink_tags_input.text = _join_csv(d.tags)

	# Ingredients in UI spiegeln
	_pending_ingredients.clear()
	_clear_children(ingredient_list)
	for ia in d.ingredients:
		if ia == null: continue
		_pending_ingredients.append(ia)
		_add_ingredient_row_ui(ia.liquid, ia.amount_ml)


# ─────────────────────────────
# SAVE pro Tab
# ─────────────────────────────
func _save_mat():
	var m := RepBaseMat.new()
	m.id = mat_id_input.text.strip_edges()
	m.display_name = mat_name_input.text.strip_edges()
	m.unit = mat_unit_input.text.strip_edges()
	m.buy_price = int(mat_price_input.value)
	m.buy_amount = int(mat_amount_input.value)
	# Unlock:
	m.tier                = int(mat_tier_input.value) if mat_tier_input else 0
	m.unlock_cost         = int(mat_unlock_cost_input.value) if mat_unlock_cost_input else 0
	m.unlocked_by_default = bool(mat_unlocked_input.button_pressed) if mat_unlocked_input else true
	m.prerequisites       = _split_csv(mat_prereq_input)
	m.tags                = _split_csv(mat_tags_input)
	_save_resource(m, "%s/%s.tres" % [PATH_MATS, m.id.to_lower()])

func _save_liquid():
	var l := Liquid.new()
	l.id = liquid_id_input.text.strip_edges()
	l.display_name = liquid_name_input.text.strip_edges()
	# if liquid_mat_path and FileAccess.file_exists(liquid_mat_path.text): l.material = load(liquid_mat_path.text)
	# Unlock:
	l.tier                = int(liquid_tier_input.value) if liquid_tier_input else 0
	l.unlock_cost         = int(liquid_unlock_cost_input.value) if liquid_unlock_cost_input else 0
	l.unlocked_by_default = bool(liquid_unlocked_input.button_pressed) if liquid_unlocked_input else true
	l.prerequisites       = _split_csv(liquid_prereq_input)
	l.tags                = _split_csv(liquid_tags_input)
	_save_resource(l, "%s/%s.tres" % [PATH_LIQUIDS, l.id.to_lower()])


func _save_item():
	var i := ReplicatorItem.new()
	i.id = item_id_input.text.strip_edges()
	i.display_name = item_name_input.text.strip_edges()
	var p := item_scene_path.text.strip_edges()
	if FileAccess.file_exists(p):
		i.scene = load(p)
	i.default_ml = int(item_ml_input.value)
	# Unlock:
	i.tier                = int(item_tier_input.value) if item_tier_input else 0
	i.unlock_cost         = int(item_unlock_cost_input.value) if item_unlock_cost_input else 0
	i.unlocked_by_default = bool(item_unlocked_input.button_pressed) if item_unlocked_input else true
	i.prerequisites       = _split_csv(item_prereq_input)
	i.tags                = _split_csv(item_tags_input)
	_save_resource(i, "%s/%s.tres" % [PATH_ITEMS, i.id.to_lower()])


func _save_drink():
	var d := DrinkRecipe.new()
	d.id = drink_id_input.text.strip_edges()
	d.display_name = drink_name_input.text.strip_edges()
	d.sell_price = int(drink_price_input.value)
	d.spoil_time = float(drink_spoil_input.value)
	d.container = drink_container_input.selected if drink_container_input else 0
	# Unlock:
	d.tier                = int(drink_tier_input.value) if drink_tier_input else 0
	d.unlock_cost         = int(drink_unlock_cost_input.value) if drink_unlock_cost_input else 0
	d.unlocked_by_default = bool(drink_unlocked_input.button_pressed) if drink_unlocked_input else false
	d.prerequisites       = _split_csv(drink_prereq_input)
	d.tags                = _split_csv(drink_tags_input)

	d.ingredients.clear()
	for ing in _pending_ingredients:
		d.ingredients.append(ing)

	_save_resource(d, "%s/%s.tres" % [PATH_DRINKS, d.id.to_lower()])


# ─────────────────────────────
# CORE Save / Utils
# ─────────────────────────────
func _save_resource(res: Resource, path: String):
	var err := ResourceSaver.save(res, path)
	if err == OK:
		print("💾 Saved:", path)
		if editor_interface:
			editor_interface.edit_resource(res)
	else:
		push_error("❌ Save failed: %s (%s)" % [path, str(err)])

func _clear_children(container: Node):
	if container == null: return
	for c in container.get_children():
		c.queue_free()
		

# ─────────────────────────────
# Clear Functions
# ─────────────────────────────


func _clear_mat() -> void:
	if mat_id_input:     mat_id_input.text = ""
	if mat_name_input:   mat_name_input.text = ""
	if mat_unit_input:   mat_unit_input.text = "units"
	if mat_price_input:  mat_price_input.value = 0
	if mat_amount_input: mat_amount_input.value = 0
	if mat_tier_input:         mat_tier_input.value = 0
	if mat_unlock_cost_input:  mat_unlock_cost_input.value = 0
	if mat_unlocked_input:     mat_unlocked_input.button_pressed = true
	if mat_prereq_input:       mat_prereq_input.text = ""
	if mat_tags_input:         mat_tags_input.text = ""


func _clear_liquid() -> void:
	if liquid_id_input:    liquid_id_input.text = ""
	if liquid_name_input:  liquid_name_input.text = ""
	if liquid_mat_path:    liquid_mat_path.text = ""
	if liquid_tier_input:         liquid_tier_input.value = 0
	if liquid_unlock_cost_input:  liquid_unlock_cost_input.value = 0
	if liquid_unlocked_input:     liquid_unlocked_input.button_pressed = true
	if liquid_prereq_input:       liquid_prereq_input.text = ""
	if liquid_tags_input:         liquid_tags_input.text = ""


func _clear_item() -> void:
	if item_id_input:     item_id_input.text = ""
	if item_name_input:   item_name_input.text = ""
	if item_scene_path:   item_scene_path.text = ""
	if item_liquid_input: item_liquid_input.text = ""
	if item_ml_input:     item_ml_input.value = 0
	if item_tier_input:         item_tier_input.value = 0
	if item_unlock_cost_input:  item_unlock_cost_input.value = 0
	if item_unlocked_input:     item_unlocked_input.button_pressed = true
	if item_prereq_input:       item_prereq_input.text = ""
	if item_tags_input:         item_tags_input.text = ""


func _clear_drink() -> void:
	if drink_id_input:        drink_id_input.text = ""
	if drink_name_input:      drink_name_input.text = ""
	if drink_price_input:     drink_price_input.value = 0
	if drink_spoil_input:     drink_spoil_input.value = 0
	if drink_container_input: drink_container_input.selected = 0
	if drink_tier_input:         drink_tier_input.value = 0
	if drink_unlock_cost_input:  drink_unlock_cost_input.value = 0
	if drink_unlocked_input:     drink_unlocked_input.button_pressed = false
	if drink_prereq_input:       drink_prereq_input.text = ""
	if drink_tags_input:         drink_tags_input.text = ""
	_pending_ingredients.clear()
	_clear_children(ingredient_list)
	if ingredient_amount_input:
		ingredient_amount_input.value = 0
		
		
func _safe_set_dir(dlg: EditorFileDialog, dir: String) -> void:
	if DirAccess.dir_exists_absolute(dir):
		dlg.set_current_dir(dir)
		
		
func _safe_set_path(dlg: EditorFileDialog, path: String) -> void:
	if FileAccess.file_exists(path):
		dlg.set_current_path(path)
	else:
		var dir := path.get_base_dir()
		if DirAccess.dir_exists_absolute(dir):
			dlg.set_current_dir(dir)
			

func _split_csv(le: LineEdit) -> PackedStringArray:
	if le == null: 
		return PackedStringArray()
	var raw := le.text.strip_edges()
	if raw == "":
		return PackedStringArray()
	var parts := raw.split(",", false)
	var out := PackedStringArray()
	for p in parts:
		var t := String(p).strip_edges()
		if t != "":
			out.append(t)
	return out
	

func _join_csv(arr: PackedStringArray) -> String:
	return ",".join(arr)
