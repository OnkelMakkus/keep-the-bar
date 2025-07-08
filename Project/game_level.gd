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

var player: CharacterBody3D

var paused := false

func _ready() -> void:
	player = Gamemanager.get_object("Player")
	Signalmanager.update_money.emit(0)
	Gamemanager.serving_container = serving_container
	
	set_process_unhandled_input(true)
	
	Signalmanager.open_shop.connect(open_shop)
	Signalmanager.open_order.connect(open_order)
	Signalmanager.all_the_main_menu_stuff.connect(allTheMainMenuStuff)
	
	
func _process(_delta: float) -> void:
	if Gamemanager.is_open:
		Signalmanager.update_time_left.emit(is_open_timer.time_left)
		
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused and not Gamemanager.is_in_menu:
			# Spiel pausieren
			allTheMainMenuStuff()
			
		else:
			# Spiel fortsetzen
			if not Gamemanager.is_in_menu:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				player.mouse_captured = true
				player.quit_menu_open = false
				get_tree().paused = false
				Signalmanager.switch_menuBtn_visibility.emit(false)


func allTheMainMenuStuff():
	crosshair.visible = false
	info_label.visible = false
	info_text_label.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.mouse_captured = false
	player.quit_menu_open = true
	get_tree().paused = true
	Signalmanager.switch_menuBtn_visibility.emit(true)
	
	
func open_shop():
	if is_open_timer.is_stopped():
		is_open_timer.start()
		Gamemanager.is_open = true
		open_label.text = "CLOSE"
		print("IsOpenTimer gestartet")
	else:
		is_open_timer.stop()
		Gamemanager.is_open = false
		open_label.text = "OPEN"
		print("IsOpenTimer gestoppt")
		Signalmanager.close_store.emit()


func open_order():
	var ordermenu = Gamemanager.ORDER_MENU.instantiate()
	add_child(ordermenu)
	

func _on_is_open_timer_timeout() -> void:
	is_open_timer.stop()
	open_label.text = "OPEN"
	Gamemanager.is_open = false
	Signalmanager.close_store.emit()


func _on_option_btn_pressed() -> void:
	var optionmenu = Gamemanager.OPTION_MENU.instantiate()
	add_child(optionmenu)
