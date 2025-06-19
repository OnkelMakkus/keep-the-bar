#game_level.gd
extends Node3D

@onready var quit_btn: Button = $UI/MarginContainer/VBoxContainer/QuitBtn
@onready var resume_btn: Button = $UI/MarginContainer/VBoxContainer/ResumeBtn
@onready var is_open_timer: Timer = $IsOpenTimer
@onready var open_label: Label3D = $Open_Schild/Label3D

@onready var serving_container: Node3D = $serving_container

var player: CharacterBody3D

var paused := false

func _ready() -> void:
	player = Gamemanager.get_object("Player")
	Signalmanager.update_money.emit(0)
	Gamemanager.serving_container = serving_container
	
	set_process_unhandled_input(true)
	
	Signalmanager.open_shop.connect(open_shop)
	
	
func _process(_delta: float) -> void:
	if Gamemanager.is_open:
		Signalmanager.update_time_left.emit(is_open_timer.time_left)
		
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			# Spiel pausieren
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			player.mouse_captured = false
			player.quit_menu_open = true
			get_tree().paused = true
			Signalmanager.switch_menuBtn_visibility.emit(true)
		else:
			# Spiel fortsetzen
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			player.mouse_captured = true
			player.quit_menu_open = false
			get_tree().paused = false
			Signalmanager.switch_menuBtn_visibility.emit(false)

		
func open_shop():
	is_open_timer.start()
	Gamemanager.is_open = true
	open_label.text = "OPENED"
	print("IsOpenTimer gestartet")	


func _on_is_open_timer_timeout() -> void:
	is_open_timer.stop()
	open_label.text = "OPEN"
	Gamemanager.is_open = false
