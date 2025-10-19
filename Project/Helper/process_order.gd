# process_order.gd  (final)
extends Node3D

@export var shipment_timer: Timer

# --- alter Weg (kompatibel) ---
var payload_alco := 0
var payload_molor := 0
var payload_sweet := 0
var payload_matter := 0

# --- neuer, generischer Weg ---
var payload_by_id: Dictionary = {}   # id -> amount (units)

var _tick := 0.0
const UI_UPDATE_INTERVAL := 0.2

func _ready() -> void:
	set_process(true)
	if shipment_timer and not shipment_timer.timeout.is_connected(_on_Shipment_Timer_timeout):
		shipment_timer.timeout.connect(_on_Shipment_Timer_timeout)

func _process(delta: float) -> void:
	if shipment_timer and not shipment_timer.is_stopped():
		_tick += delta
		if _tick >= UI_UPDATE_INTERVAL:
			_emit_time_left()
			_tick = 0.0

# ---------- ALT (4 feste Materialien) ----------
func start_order_process(alk:int, color:int, sweet:int, mats:int, duration:float) -> void:
	payload_alco   = max(0, alk)
	payload_molor  = max(0, color)
	payload_sweet  = max(0, sweet)
	payload_matter = max(0, mats)
	payload_by_id.clear()  # sicherstellen, dass der neue Weg leer ist
	_start_timer(duration)

# ---------- NEU (beliebige Ressourcen) ----------
func start_order_process_dict(payload: Dictionary, duration: float) -> void:
	payload_by_id = {}
	# nur sinnvolle Einträge übernehmen
	for id in payload.keys():
		var amt := int(payload[id])
		if amt > 0 and ReplicatorDB.get_mat(String(id)) != null:
			payload_by_id[String(id)] = amt
	_start_timer(duration)

# ---------- Timer/Countdown ----------
func _start_timer(duration: float) -> void:
	if shipment_timer:
		shipment_timer.stop()
		shipment_timer.one_shot = true
		shipment_timer.wait_time = max(0.01, duration)
		shipment_timer.start()
	_emit_time_left()

func _emit_time_left() -> void:
	if shipment_timer == null:
		return
	var left := shipment_timer.time_left
	if left <= 0.0:
		Signalmanager.ship_order_display.emit("00:00")
		return
	var total := int(ceil(left))
	@warning_ignore("integer_division")
	var mm := total / 60
	var ss := total % 60
	Signalmanager.ship_order_display.emit("%02d:%02d" % [mm, ss])

# ---------- Lieferung verbuchen ----------
func _on_Shipment_Timer_timeout() -> void:
	if payload_by_id.size() > 0:
		# generisch: alle IDs gutschreiben
		for id in payload_by_id.keys():
			ReplicatorDB.add_mat_amount(String(id), int(payload_by_id[id]))
	else:
		# legacy: die 4 festen Felder
		ReplicatorDB.add_mat_amount("AlcoMol",         payload_alco)
		ReplicatorDB.add_mat_amount("MolOr",           payload_molor)
		ReplicatorDB.add_mat_amount("Sweet_Molecules", payload_sweet)
		ReplicatorDB.add_mat_amount("Matter",          payload_matter)

	Signalmanager.update_info_text_label.emit("Shipment arrived")
	Signalmanager.update_res_display.emit()
	Signalmanager.update_ressource_label.emit()

	Signalmanager.ship_order_display.emit("—")
	set_process(false)
	queue_free()
