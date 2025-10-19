# order_menu.gd
extends Control

@export var PROCESS_ORDER: PackedScene
@export var color_rect: ColorRect
@export var title_label: Label
@export var header_container: HBoxContainer
@export var rows_scroll: ScrollContainer
@export var rows_container: GridContainer
@export var current_money_label: Label
@export var estimated_money_label: Label
@export var cancel_btn: Button
@export var set_order_btn: Button
@export var timer_duration: float = 250.0

# State
var temp_amount_by_id: Dictionary = {}   # id -> Units (bestellt, in "Units"/buy_amount-Schritten)
var temp_cost_by_id: Dictionary   = {}   # id -> Coins
var row_widgets_by_id: Dictionary = {}   # id -> {stock, price, order}
var temp_money: int = 0

# Layout-Konstanten (passen zur Headerbreite)
const COL_W_NAME  := 240
const COL_W_NUM   := 90
const BTN_W       := 32
const BTN_H       := 28

func _ready() -> void:
	Gamemanager.is_in_menu = true
	Signalmanager.toggle_all_ui_for_replicator.emit(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if color_rect:
		color_rect.size = DisplayServer.window_get_size()

	_setup_header_labels()       # nur Texte/Breiten setzen – Labels existieren im Editor
	_setup_scroll_and_layout()   # Scroll/Center/Größen

	if cancel_btn and not cancel_btn.pressed.is_connected(_on_cancel_btn_pressed):
		cancel_btn.pressed.connect(_on_cancel_btn_pressed)
	if set_order_btn and not set_order_btn.pressed.is_connected(_on_set_order_btn_pressed):
		set_order_btn.pressed.connect(_on_set_order_btn_pressed)

	# falls DB später feuert
	if ReplicatorDB.has_signal("mats_changed") and not ReplicatorDB.mats_changed.is_connected(_rebuild_rows_from_signal):
		ReplicatorDB.mats_changed.connect(_rebuild_rows_from_signal)

	# kleinen Frame warten (falls Autoloads im selben Frame starten)
	call_deferred("_safe_build_rows")


func _process(_dt: float) -> void:
	if Input.is_action_pressed("ui_cancel") and Gamemanager.is_in_menu:
		_on_cancel_btn_pressed()

# ---------------- UI Grundsetup ----------------

func _setup_header_labels() -> void:
	if title_label:
		title_label.text = "Order Materials"
		title_label.add_theme_font_size_override("font_size", 22)

	if not header_container:
		return

	var names := ["Resource", "Stock", "Price", "–", "+", "Order"]
	# Wir gehen davon aus, dass 6 Labels im Editor vorhanden sind:
	for i in range(min(6, header_container.get_child_count())):
		var l := header_container.get_child(i) as Label
		if not l: continue
		l.text = names[i]
		l.add_theme_font_size_override("font_size", 16)
		l.modulate = Color(1,1,1,0.9)
		match i:
			0:
				l.custom_minimum_size.x = COL_W_NAME
			1,2,5:
				l.custom_minimum_size.x = COL_W_NUM
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			3,4:
				l.custom_minimum_size.x = BTN_W
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# zentrierter Header
	header_container.alignment = BoxContainer.ALIGNMENT_CENTER

func _setup_scroll_and_layout() -> void:
	if rows_scroll:
		rows_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rows_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
		rows_scroll.size_flags_horizontal  = Control.SIZE_EXPAND | Control.SIZE_FILL
		rows_scroll.size_flags_vertical    = Control.SIZE_EXPAND | Control.SIZE_FILL
		if rows_scroll.custom_minimum_size.y < 300:
			rows_scroll.custom_minimum_size.y = 300

	if rows_container:
		rows_container.columns = 6
		rows_container.add_theme_constant_override("h_separation", 16)
		rows_container.add_theme_constant_override("v_separation", 8)
		rows_container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
		rows_container.size_flags_vertical   = Control.SIZE_EXPAND | Control.SIZE_FILL

	# Feste Inhaltsbreite für Grid + Header -> so bleibt alles mittig
	var content_w := _calc_content_width()
	if header_container:
		header_container.custom_minimum_size.x = content_w
	if rows_container:
		rows_container.custom_minimum_size.x = content_w

func _calc_content_width() -> int:
	var cols := 6
	var hsep := 16
	var w := COL_W_NAME + COL_W_NUM * 3 + BTN_W * 2
	w += (cols - 1) * hsep
	return w

# ---------------- Rows bauen ----------------

func _safe_build_rows() -> void:
	await get_tree().process_frame
	_build_rows_from_db()
	_update_totals()

func _rebuild_rows_from_signal() -> void:
	_build_rows_from_db()
	_update_totals()

func _build_rows_from_db() -> void:
	_clear_rows()
	temp_amount_by_id.clear()
	temp_cost_by_id.clear()
	row_widgets_by_id.clear()

	if rows_container == null:
		push_warning("rows_container not assigned.")
		return

	var mats: Array = ReplicatorDB.all_mats()
	if mats.is_empty():
		# noch einmal probieren
		call_deferred("_safe_build_rows")
		return

	mats.sort_custom(func(a, b): return String(a.display_name).naturalnocasecmp_to(String(b.display_name)) < 0)

	var rows := 0
	for m: RepBaseMat in mats:
		rows += 1
		var id := String(m.id)
		temp_amount_by_id[id] = 0
		temp_cost_by_id[id]   = 0

		var name_lbl := Label.new()
		name_lbl.text = m.display_name
		name_lbl.custom_minimum_size.x = COL_W_NAME
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var stock_lbl := _num_label(str(m.current_amount))
		var price_lbl := _num_label(str(m.buy_price))

		var dec_btn := _small_btn("–")
		dec_btn.pressed.connect(func(): _change_amount(id, -m.buy_amount))

		var inc_btn := _small_btn("+")
		inc_btn.pressed.connect(func():
			if Gamemanager.money >= (temp_money + m.buy_price):
				_change_amount(id, m.buy_amount)
			else:
				Signalmanager.update_info_text_label.emit("Not enough money")
		)

		var order_lbl := _num_label("0")

		rows_container.add_child(name_lbl)
		rows_container.add_child(stock_lbl)
		rows_container.add_child(price_lbl)
		rows_container.add_child(dec_btn)
		rows_container.add_child(inc_btn)
		rows_container.add_child(order_lbl)

		row_widgets_by_id[id] = {
			"stock": stock_lbl,
			"price": price_lbl,
			"order": order_lbl
		}

	# ✅ Mindesthöhe nach Anzahl Zeilen -> bessere Scrollbarkeit, kein H-Scroll nötig
	rows_container.custom_minimum_size.y = max(rows * 36, 150)

func _clear_rows() -> void:
	if rows_container == null: return
	for c in rows_container.get_children():
		rows_container.remove_child(c)
		c.queue_free()

# ---------------- Helpers (UI) ----------------

func _num_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = COL_W_NUM
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _small_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(BTN_W, BTN_H)
	b.focus_mode = Control.FOCUS_NONE
	return b

# ---------------- Logik ----------------

func _change_amount(id: String, delta_units: int) -> void:
	var new_units = max(0, int(temp_amount_by_id.get(id, 0)) + delta_units)
	temp_amount_by_id[id] = new_units

	var m := ReplicatorDB.get_mat(id)
	if m:
		var packs := int(ceil(float(new_units) / m.buy_amount)) if new_units > 0 else 0
		temp_cost_by_id[id] = packs * m.buy_price

	var w = row_widgets_by_id.get(id, {})
	if w.has("order"):
		(w["order"] as Label).text = str(new_units)

	_update_totals()

func _update_totals() -> void:
	for id in row_widgets_by_id.keys():
		var m := ReplicatorDB.get_mat(String(id))
		if m and row_widgets_by_id[id].has("stock"):
			(row_widgets_by_id[id]["stock"] as Label).text = str(m.current_amount)

	temp_money = 0
	for c in temp_cost_by_id.values():
		temp_money += int(c)

	if current_money_label:
		current_money_label.text = "Current Money: " + str(Gamemanager.money)
	if estimated_money_label:
		estimated_money_label.text = "Estimated expenses: " + str(temp_money)

func _refresh_stocks_only() -> void:
	for id in row_widgets_by_id.keys():
		var m := ReplicatorDB.get_mat(String(id))
		if m and row_widgets_by_id[id].has("stock"):
			(row_widgets_by_id[id]["stock"] as Label).text = str(m.current_amount)

# ---------------- Buttons ----------------

func _on_cancel_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Signalmanager.update_ressource_label.emit()
	queue_free()

func _on_set_order_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)

	if Gamemanager.money < temp_money:
		Signalmanager.update_info_text_label.emit("Not enough money")
		Signalmanager.update_ressource_label.emit()
		Signalmanager.update_res_display.emit()
		queue_free()
		return

	# ❗ Geld über zentrales HUD-Signal abziehen (HUD aktualisiert sich automatisch)
	Signalmanager.update_money.emit(-temp_money)

	var payload := {}
	for id in temp_amount_by_id.keys():
		var units := int(temp_amount_by_id[id])
		if units > 0:
			payload[id] = units

	var po := PROCESS_ORDER.instantiate()
	Gamemanager.spawnmarker.call_deferred("add_child", po)
	po.call_deferred("start_order_process_dict", payload, timer_duration)

	Signalmanager.update_ressource_label.emit()
	Signalmanager.update_res_display.emit()
	queue_free()
