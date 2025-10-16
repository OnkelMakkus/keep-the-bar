#ui.gd
extends Control
var player: Player

@export_category("Buttons")
@export var quit_btn: Button 
@export var resume_btn: Button 
@export var option_btn: Button
@export var save_btn: Button
@export var load_btn: Button

@export_category("label")
@export var kohle_lbl: Label 
@export var time_lbl: Label 
@export var alco_mol_lbl: Label 
@export var mol_or_lbl: Label
@export var matter_lbl: Label
@export var sweet_molecules_lbl: Label
@export var delivery_lbl: Label
@export var info_text_label: Label
@export var info_label: Label 

@export_category("Misc")
@export var menü_main: MarginContainer
@export var crosshair: ColorRect
@export var info_text_timer: Timer
@export var hud_info_timer: Timer
@export var hud_info_background: TextureRect

const CROSSHAIR_IDLE  := Color(1, 1, 1, 0.9)   # weiß
const CROSSHAIR_HOT   := Color(1, 0.9, 0.2, 1) # gelblich
var _crosshair_tween: Tween


func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	option_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = Gamemanager.get_object("Player") as Player
	
	Gamemanager.main_ui = self
	
	switch_menu_visibility(false)
	
	player = Gamemanager.get_object("Player") as Player
	if player:
		player.target_changed.connect(_on_player_target_changed)
	
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

func show_hud_info():
	hud_info_timer.start()
	set_opacity(hud_info_background, 1)
	

func update_money(amount: int):
	Gamemanager.money += amount
	kohle_lbl.text = "Kohle: " + str(Gamemanager.money)
	show_hud_info()
	
	
func update_info_text_label(info: String):
	info_text_label.text = info
	info_text_timer.start()
	
	
func update_res_display():
	show_hud_info()
	alco_mol_lbl.text = "AlcoMol: " + str(Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"])
	mol_or_lbl.text = "MolOr: " + str(Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"])
	sweet_molecules_lbl.text = "Sweet Molecules: " + str(Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"])
	matter_lbl.text = "Matter: " + str(Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"])
	

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
	
	
func set_opacity(node: TextureRect, value: float, duration: float = 0.5):
	if node == null:
		return

	var start_alpha = node.modulate.a
	var end_alpha = clampf(value, 0.0, 1.0)

	# Tween erstellen
	var tween = node.get_tree().create_tween()
	tween.tween_property(node, "modulate:a", end_alpha, duration).from(start_alpha)
	

func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_resume_btn_button_down() -> void:
	get_tree().paused = false
	crosshair.visible = true
	info_label.visible = true
	if player:
		player.set_menu_open(false)  # Maus capturen + is_in_menu=false
	Signalmanager.switch_menuBtn_visibility.emit(false)


func _on_info_text_timer_timeout() -> void:
	info_text_label.text = ""
	delivery_lbl.text = ""
	info_text_label.visible = false


func _on_save_btn_pressed() -> void:
	print ("saving")
	Savemanager.savegame()
	_on_resume_btn_button_down()


func _on_load_btn_pressed() -> void:
	print ("loading")
	Savemanager.loadgame()
	_on_resume_btn_button_down()


func _on_hud_info_timer_timeout() -> void:
	set_opacity(hud_info_background, 0.5)
	

func _on_player_target_changed(new_target: Object) -> void:
	# Gruppen, die als „interaktiv“ gelten
	var groups: Array[String] = [
		"Pickupable", "Bottle", "Glass",
		"Customer", "Recycler_Button", "Replicator",
		"Open_Schild", "Order_Schild"
	]

	var hot := false
	if new_target != null:
		var cur_owner := Gamemanager.find_owner_in_any_group(new_target, groups)
		hot = cur_owner != null

	_set_crosshair_color(CROSSHAIR_HOT if hot else CROSSHAIR_IDLE)



func _set_crosshair_color(target: Color, duration: float = 0.12) -> void:
	if not is_instance_valid(crosshair):
		return
	if _crosshair_tween:
		_crosshair_tween.kill()
	_crosshair_tween = create_tween()
	_crosshair_tween.tween_property(crosshair, "color", target, duration)
