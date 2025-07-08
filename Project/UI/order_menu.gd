extends Control

@export var PROCESS_ORDER : PackedScene
@export var order_menu: Control 
@export var color_rect: ColorRect 
@export var aspect_ratio_container: AspectRatioContainer

@export var res_01_label: Label 
@export var res_02_label: Label 
@export var res_03_label: Label 
@export var res_04_label: Label 

@export var amount_01_label: Label 
@export var amount_02_label: Label 
@export var amount_03_label: Label 
@export var amount_04_label: Label
 
@export var price_01_label: Label 
@export var price_02_label: Label 
@export var price_03_label: Label 
@export var price_04_label: Label 

@export var order_01_label: Label 
@export var order_02_label: Label
@export var order_03_label: Label
@export var order_04_label: Label

@export var current_money_label: Label
@export var estimated_money_label: Label

var temp_money_AlcoMol :int
var temp_money_MolOr :int
var temp_money_Sweet_Molecules :int
var temp_money_matter : int

var temp_money : int

var temp_AlcoMol: int = 0
var temp_MolOr : int = 0
var temp_Sweet_Molecules: int = 0
var temp_matter: int = 0


func _ready() -> void:
	Gamemanager.is_in_menu = true
	
	Signalmanager.toggle_all_ui_for_replicator.emit(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var screen := DisplayServer.window_get_current_screen()
	var screen_size = DisplayServer.window_get_size()
	
	order_menu.size = screen_size
	color_rect.size = screen_size
	aspect_ratio_container.size = screen_size
	
	res_01_label.text = "AlcoMol"
	res_02_label.text = "MolOr"
	res_03_label.text = "Sweet Molecules"
	res_04_label.text = "Matter"
	
	amount_01_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"])
	amount_02_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"])
	amount_03_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"])
	amount_04_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"])

	price_01_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_price"])
	price_02_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_price"])
	price_03_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_price"])
	price_04_label.text = str(Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_price"])
	
	update_labels()
	
	
func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_cancel") and Gamemanager.is_in_menu:
		_on_cancel_btn_pressed()
		
func calc_temp_money():
	temp_money = temp_money_AlcoMol + temp_money_MolOr + temp_money_Sweet_Molecules + temp_money_matter
	update_labels()
	

func _on_cancel_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Signalmanager.update_ressource_label.emit()
	self.queue_free()


func _on_set_order_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	
	if Gamemanager.money >= temp_money:
		Gamemanager.money -= temp_money
		
		var process_order = PROCESS_ORDER.instantiate()
		Gamemanager.spawnmarker.call_deferred("add_child", process_order)
		process_order.call_deferred("start_order_process", temp_AlcoMol, temp_MolOr, temp_Sweet_Molecules, temp_matter)
		
	else:
		Signalmanager.update_info_text_label.emit("Not enough money")
		
	Signalmanager.update_ressource_label.emit()
	Signalmanager.update_res_display.emit()
	self.queue_free()
	
	
func update_labels():
	current_money_label.text = "Current Money: " + str(Gamemanager.money)
	estimated_money_label.text = "Estimated expenses: " + str(temp_money)
	order_01_label.text = "AlcoMol: " + str(temp_AlcoMol)
	order_02_label.text = "MolOr: " + str(temp_MolOr)
	order_03_label.text = "Sweet Molecules: " + str(temp_Sweet_Molecules)
	order_04_label.text = "Matter: " + str(temp_matter)


func _on_decrease_01_btn_pressed() -> void:
	if temp_money_AlcoMol >= Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_price"]:
		temp_money_AlcoMol -= Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_price"]
		temp_AlcoMol -= Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_amount"]
	calc_temp_money()


func _on_decrease_02_btn_pressed() -> void:
	if temp_money_MolOr >= Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_price"]:
		temp_money_MolOr -= Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_price"]
		temp_MolOr -= Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_amount"]
	calc_temp_money()


func _on_decrease_03_btn_pressed() -> void:
	if temp_money_Sweet_Molecules >= Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_price"]:
		temp_money_Sweet_Molecules -= Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_price"]
		temp_Sweet_Molecules -= Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_amount"]
	calc_temp_money()
	
	
func _on_decrease_04_btn_pressed() -> void:
	if temp_money_matter >= Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_price"]:
		temp_money_matter -= Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_price"]
		temp_matter -= Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_amount"]
	calc_temp_money()


func _on_increase_01_btn_pressed() -> void:
	temp_money_AlcoMol += Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_price"]
	temp_AlcoMol += Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["buy_amount"]
	calc_temp_money()	


func _on_increase_02_btn_pressed() -> void:
	temp_money_MolOr += Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_price"]
	temp_MolOr += Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["buy_amount"]
	calc_temp_money()


func _on_increase_03_btn_pressed() -> void:
	temp_money_Sweet_Molecules += Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_price"]
	temp_Sweet_Molecules += Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["buy_amount"]
	calc_temp_money()


func _on_increase_04_btn_pressed() -> void:
	temp_money_matter += Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_price"]
	temp_matter += Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["buy_amount"]
	calc_temp_money()
