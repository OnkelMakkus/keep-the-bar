#ui.gd
extends Control

@export var menü_main: MarginContainer

@export var quit_btn: Button 
@export var resume_btn: Button 
@export var option_btn: Button

@export var kohle_lbl: Label 
@export var time_lbl: Label 
@export var alco_mol_lbl: Label 
@export var mol_or_lbl: Label
@export var matter_lbl: Label
@export var sweet_molecules_lbl: Label
@export var delivery_lbl: Label
@export var info_text_label: Label

@export var crosshair: ColorRect
@export var info_label: Label 

@export var info_text_timer: Timer


func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	option_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	Gamemanager.main_ui = self
	
	switch_menu_visibility(false)
	
	Signalmanager.update_time_left.connect(update_time_lbl)
	Signalmanager.update_money.connect(update_money)
	Signalmanager.switch_menuBtn_visibility.connect(switch_menu_visibility)
	Signalmanager.update_info_label.connect(update_info_label)
	Signalmanager.toggle_all_ui_for_replicator.connect(toggle_all_ui_for_replicator)
	Signalmanager.update_res_display.connect(update_res_display)
	Signalmanager.ship_order_display.connect(update_delivery_time_label)
	Signalmanager.update_info_text_label.connect(update_info_text_label)
	
	Signalmanager.update_res_display.emit()
	
	time_lbl.text = ""
	info_label.text = ""


func update_money(amount: int):
	Gamemanager.money += amount
	kohle_lbl.text = "Kohle: " + str(Gamemanager.money)
	
	
func update_info_text_label(info: String):
	info_text_label.text = info
	info_text_timer.start()
	
	
func update_res_display():
	alco_mol_lbl.text = "AlcoMol: " + str(Gamemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"])
	mol_or_lbl.text = "MolOr: " + str(Gamemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"])
	sweet_molecules_lbl.text = "Sweet Molecules: " + str(Gamemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"])
	matter_lbl.text = "Matter: " + str(Gamemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"])
	

func update_info_label(info: String):
	info_label.text = info
	
	
func toggle_all_ui_for_replicator(value: bool):
	info_label.visible = value
	crosshair.visible = value
	kohle_lbl.visible = value
	time_lbl.visible = value
	alco_mol_lbl.visible = value
	mol_or_lbl.visible = value
	matter_lbl.visible = value
	sweet_molecules_lbl.visible = value
	delivery_lbl.visible = value
	info_text_label.visible = value
	

func _on_quit_btn_button_up() -> void:
	get_tree().quit()
	

func switch_menu_visibility(value: bool):
	quit_btn.visible = value
	resume_btn.visible = value
	menü_main.visible = value
	option_btn.visible = value
	
	
func update_delivery_time_label(delivery_time: String):
	delivery_lbl.text = "Time to delivery: " + delivery_time

func update_time_lbl(time):
	# time ist eine float-Zahl in Sekunden, z. B. 213.7
	@warning_ignore("integer_division")
	var minutes = int(time) / 60
	@warning_ignore("integer_division")
	var seconds = int(time) % 60
	# Optional: mit führender Null
	var min_str = str(minutes).pad_zeros(2)
	var sec_str = str(seconds).pad_zeros(2)
	time_lbl.text = "Time left: %s:%s" % [min_str, sec_str]
	

func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_resume_btn_button_down() -> void:
	get_tree().paused = false
	crosshair.visible = true
	info_label.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.switch_menuBtn_visibility.emit(false)
	# und ggf. deinen player anpassen:
	var player = Gamemanager.get_object("Player")
	if player:
		player.mouse_captured = true
		player.quit_menu_open = false


func _on_info_text_timer_timeout() -> void:
	info_text_label.text = ""
	delivery_lbl.text = ""
	info_text_label.visible = false
