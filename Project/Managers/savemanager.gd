extends Node

func gather_save_data():
	var save = {
		"money": Gamemanager.money,
		"alk": Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"],
		"farbe": Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"],
		"sweet": Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"],
		"matter": Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"],
		"fullscreen": Gamemanager.fullscreen,
		"mousesens": Gamemanager.mouse_sensitivity,
	}
	return save
	
	
func rewrite_saved_data(save):
	Gamemanager.money = save.money
	Resourcemanager.REPLICATOR_RESSOURCES["AlcoMol"]["current_amount"] = save.alk
	Resourcemanager.REPLICATOR_RESSOURCES["MolOr"]["current_amount"] = save.farbe
	Resourcemanager.REPLICATOR_RESSOURCES["Sweet_Molecules"]["current_amount"] = save.sweet
	Resourcemanager.REPLICATOR_RESSOURCES["Matter"]["current_amount"] = save.matter
	Gamemanager.fullscreen = save.fullscreen
	Gamemanager.mouse_sensitivity = save.mousesens
		
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, Gamemanager.fullscreen)
	
	Signalmanager.update_info_label.emit()
	Signalmanager.update_money.emit(0)
	Signalmanager.update_ressource_label.emit()
	Signalmanager.update_res_display.emit()
		
	
func savegame():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save_data = gather_save_data()
	var json_string = JSON.stringify(save_data)
	save_file.store_line(json_string)
	
	
func loadgame():
	if not FileAccess.file_exists("user://savegame.save"):
		print ("No Save Found")
		return # Error! We don't have a save to load.
		
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

			# Creates the helper class to interact with JSON.
		var json = JSON.new()
			
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

			# Get the data from the JSON object.
		var node_data = json.data
		print (node_data)
		rewrite_saved_data(node_data)
