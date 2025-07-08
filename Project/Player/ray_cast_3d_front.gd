extends RayCast3D

class_name TargetRay

signal target_changed(new_target)
@export var player: CharacterBody3D


var current_target : Object = null     # zuletzt getroffener Collider
var highlighted_object: Node3D = null

func _process(_delta):
	var hit: Object = null

	if self.is_colliding():
		hit = self.get_collider()

	if hit != current_target:
		current_target = hit
		emit_signal("target_changed", current_target)
		
	update_highlight()
	check_which_object_it_is(hit)

func get_target() -> Object:
	return current_target              # Player kann jederzeit abfragen


func check_which_object_it_is(hit):
	if !is_colliding():
		Signalmanager.update_info_label.emit("")
		return
	
	if hit == null:
		Signalmanager.update_info_label.emit("")
		return
		
	if !hit.has_method("show_besitzer"):
		Signalmanager.update_info_label.emit("")
		return

	var besitzer = hit.show_besitzer()
		
	if besitzer == null:
		Signalmanager.update_info_label.emit("")
		return
		
	if (besitzer.has_method("clicked_by_player") or not besitzer.has_method("clicked_by_player")):
		Signalmanager.update_info_label.emit(besitzer.label_name)
	else:
		Signalmanager.update_info_label.emit("")
		
		
func interact():
	if player.held_object:
		if is_colliding():
			if get_target().has_method("show_besitzer") and get_target().show_besitzer().is_in_group("Recycler"):
				player.hand_slot.remove_child(player.held_object)
				get_target().show_besitzer().store_mats(player.held_object)
				player.prepare_for_recycling = true
		player.drop_object()
			
	else:
		if is_colliding():
			var hit = get_collider()
			
			var recycler_owner = Gamemanager.find_owner_of_group(hit, "Recycler_Button")
			if recycler_owner:
				Signalmanager.recycle.emit()
				return
				
			var open_schild_owner = Gamemanager.find_owner_of_group(hit, "Open_Schild")
			if open_schild_owner:
				Signalmanager.open_shop.emit()
				return 
				
			var order_schild_owner = Gamemanager.find_owner_of_group(hit, "Order_Schild")
			if order_schild_owner:
				Signalmanager.open_order.emit()
				return 
				
			var replicator_owner = Gamemanager.find_owner_of_group(hit, "Replicator")
			if replicator_owner and not Gamemanager.replicator_open:
				replicator_owner.open_ui()
				return
			
			var customer = Gamemanager.find_owner_of_group(hit, "Customer")
			if customer and customer.has_method("clicked_by_player") and not player.held_object:
				
				customer.clicked_by_player()
				return
			
			player.try_pickup()
			

func update_highlight():
	if is_colliding():
		var hit = get_collider()
		var obj = Gamemanager.find_owner_of_group(hit, "Pickupable")
		if obj:
			if highlighted_object and highlighted_object != obj:
				Gamemanager.highlight_object(highlighted_object, false)
			Gamemanager.highlight_object(obj, true)
			highlighted_object = obj
		else:
			if highlighted_object:
				Gamemanager.highlight_object(highlighted_object, false)
				highlighted_object = null
	else:
		if highlighted_object:
			Gamemanager.highlight_object(highlighted_object, false)
			highlighted_object = null
	
