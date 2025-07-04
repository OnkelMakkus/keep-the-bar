extends Control

@onready var mouse_sense_value_lbl: Label = $GridContainer/MouseSenseValueLbl
@onready var mouse_sense_slider: HSlider = $GridContainer/MouseSenseSlider
@onready var back_btn: Button = $GridContainer/MarginContainer2/BackBtn

@onready var fov_value_lbl: Label = $GridContainer/FOVValueLbl
@onready var fov_slider: HSlider = $GridContainer/FOVSlider


func _ready() -> void:
	mouse_sense_value_lbl.process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_sense_slider.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	Gamemanager.is_in_menu = true
	Signalmanager.toggle_all_ui_for_replicator.emit(false)
	Signalmanager.switch_menuBtn_visibility.emit(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	back_btn.pressed.connect(_on_back_btn_pressed)
	
	mouse_sense_slider.value = Gamemanager.mouse_sensitivity
	mouse_sense_value_lbl.text = str(mouse_sense_slider.value)
	fov_value_lbl.text = str(int(fov_slider.value))
	print (mouse_sense_slider.value)

func _on_back_btn_pressed() -> void:
	Gamemanager.is_in_menu = false
	Signalmanager.toggle_all_ui_for_replicator.emit(true)
	Signalmanager.switch_menuBtn_visibility.emit(true)
	Signalmanager.all_the_main_menu_stuff.emit()
	print ("geht doch eigentlich")
	self.queue_free()


func _on_mouse_sense_slider_drag_ended(_value_changed: bool) -> void:
	Gamemanager.mouse_sensitivity = mouse_sense_slider.value


func _on_mouse_sense_slider_value_changed(value: float) -> void:
	mouse_sense_value_lbl.text = str(mouse_sense_slider.value)


func _on_fov_slider_drag_ended(_value_changed: bool) -> void:
	Gamemanager.FOV = int(fov_slider.value)
	#Signalmanager.change_fov.emit()


func _on_fov_slider_value_changed(value: float) -> void:
	fov_value_lbl.text = str(int(fov_slider.value))
