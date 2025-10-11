extends Node3D

@onready var shipment_timer: Timer = $Shipment_Timer
@onready var label_timer: Timer = $Label_Timer

var temp_AlcoMol
var temp_MolOr
var temp_Sweet_Molecules
var temp_Matter

func start_order_process(alk, color, sweet, mats, duration):
	temp_AlcoMol = alk
	temp_MolOr = color
	temp_Sweet_Molecules = sweet
	temp_Matter = mats
	
	label_timer.wait_time = duration
	label_timer.start()


func _on_shipment_timer_timeout() -> void:
	Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"] += temp_AlcoMol
	Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"] += temp_MolOr
	Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"] += temp_Sweet_Molecules
	Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"] += temp_Matter	
	
	Signalmanager.update_info_text_label.emit("Shipment arrived")
	queue_free()


func _on_label_timer_timeout() -> void:
	# Sekunden aufrunden, damit 4.7 s → 5 s wird.
	var total_sec := int(ceil(shipment_timer.time_left))

	@warning_ignore("integer_division")
	var minutes := total_sec / 60        # ganzzahlige Division
	var seconds := total_sec % 60        # Rest-Operator

	# Als String "MM:SS" (zwei Stellen, führende Null)
	var mmss := "%02d:%02d" % [minutes, seconds]

	# Variante 1 – String senden
	Signalmanager.ship_order_display.emit(mmss)
