extends Control

@export var mouse_sense_value_lbl: Label 
@export var mouse_sense_slider: HSlider
@export var back_btn: Button 
@export var fullscreen_button: CheckButton



func _ready() -> void:
	mouse_sense_value_lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_sense_slider.process_mode = Node.PROCESS_MODE_ALWAYS
	fullscreen_button.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	Gamemanager.is_in_menu = true
	Signalmanager.toggle_all_ui_for_replicator.emit(false)
	Signalmanager.switch_menuBtn_visibility.emit(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	back_btn.pressed.connect(_on_back_btn_pressed)
	
	mouse_sense_slider.value = Gamemanager.mouse_sensitivity * 1000
	mouse_sense_value_lbl.text = str(mouse_sense_slider.value)
	
	print (mouse_sense_slider.value)

func _on_back_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Signalmanager.switch_menuBtn_visibility.emit(true)
	Signalmanager.all_the_main_menu_stuff.emit()
	print ("geht doch eigentlich")
	self.queue_free()


func _on_mouse_sense_slider_drag_ended(_value_changed: bool) -> void:
	Gamemanager.mouse_sensitivity = mouse_sense_slider.value / 1000
	print (mouse_sense_slider.value / 1000)


func _on_mouse_sense_slider_value_changed(value: float) -> void:
	mouse_sense_value_lbl.text = str(mouse_sense_slider.value)

func _on_check_button_toggled(toggled_on: bool) -> void:
	print ("toggled")
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, toggled_on)
	var screen := DisplayServer.window_get_current_screen()
	var size := DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
	_set_camera_fov(size)

func _set_camera_fov(screen_size: Vector2):
	#const V_FOV := 75.0                       # dein Basiswert (vertikal)
	
	# Falls du lieber horizontal fixieren willst, nimm die beiden Zeilen darunter:
	const H_FOV_DESIRED := 100.0
	var V_FOV = rad_to_deg(2.0 * atan(tan(deg_to_rad(H_FOV_DESIRED) * 0.5) / (screen_size.x / screen_size.y)))
	
	var cam := get_node_or_null("Camera3D")
	if cam:
		cam.fov = V_FOV                       # vertikale FOV in Grad


func _on_check_button_mouse_entered() -> void:
	print ("mouse entered")
