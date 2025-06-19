#ui.gd
extends CanvasLayer
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn
@onready var resume_btn: Button = $MarginContainer/VBoxContainer/ResumeBtn

@onready var kohle_lbl: Label = $MarginContainer2/VBoxContainer/Kohle_lbl
@onready var time_lbl: Label = $MarginContainer2/VBoxContainer/time_lbl


func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	Signalmanager.update_time_left.connect(update_time_lbl)
	Signalmanager.update_money.connect(update_money)
	Signalmanager.switch_menuBtn_visibility.connect(switch_menu_visibility)
	
	var crosshair = ColorRect.new()
	crosshair.color = Color.BLACK
	crosshair.size = Vector2(4, 4)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Nicht klickbar
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.position = Vector2(-2, -2)  # zentrieren
	add_child(crosshair)
	quit_btn.visible = false
	resume_btn.visible = false
	
	time_lbl.text = ""


func update_money(amount: int):
	Gamemanager.money += amount
	kohle_lbl.text = "Kohle: " + str(Gamemanager.money)
	

func _on_quit_btn_button_up() -> void:
	get_tree().quit()
	

func switch_menu_visibility(value: bool):
	quit_btn.visible = value
	resume_btn.visible = value
	

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
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Signalmanager.switch_menuBtn_visibility.emit(false)
	# und ggf. deinen player anpassen:
	var player = Gamemanager.get_object("Player")
	if player:
		player.mouse_captured = true
		player.quit_menu_open = false
