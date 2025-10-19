#game_level.gd
extends Node3D

@export var quit_btn: Button 
@export var resume_btn: Button 
@export var is_open_timer: Timer 
@export var open_label: Label3D 
@export var crosshair: ColorRect
@export var info_label: Label
@export var option_btn: Button
@export var info_text_label: Label


@export var serving_container: Node3D 

var player: Player

var paused := false

func _ready() -> void:
	player = Gamemanager.get_object("Player") as Player
	Signalmanager.update_money.emit(0)
	Gamemanager.serving_container = serving_container
	
	set_process_unhandled_input(true)
	
	Signalmanager.open_shop.connect(open_shop)
	Signalmanager.open_order.connect(open_order)
	Signalmanager.all_the_main_menu_stuff.connect(allTheMainMenuStuff)
	Signalmanager.update_open_status.emit(Gamemanager.is_open)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused and not Gamemanager.is_in_menu:
			# Spiel pausieren
			allTheMainMenuStuff()
			
		else:
			# Spiel fortsetzen
			if not Gamemanager.is_in_menu:
				player.set_menu_open(false)
				get_tree().paused = false
				Signalmanager.switch_menuBtn_visibility.emit(false)


func allTheMainMenuStuff():
	crosshair.visible = false
	info_label.visible = false
	info_text_label.visible = false
	
	player.set_menu_open(true)
	get_tree().paused = true
	Signalmanager.switch_menuBtn_visibility.emit(true)
	
	
func open_shop():
	if not Gamemanager.is_open:
		Gamemanager.is_open = true
		open_label.text = "CLOSE"
		Signalmanager.update_open_status.emit(Gamemanager.is_open)
	else:
		Gamemanager.is_open = false
		open_label.text = "OPEN"
		Signalmanager.close_store.emit()
		Signalmanager.update_open_status.emit(Gamemanager.is_open)


func open_order():
	var ordermenu = Gamemanager.ORDER_MENU.instantiate()
	add_child(ordermenu)


func _on_option_btn_pressed() -> void:
	var optionmenu = Gamemanager.OPTION_MENU.instantiate()
	add_child(optionmenu)
