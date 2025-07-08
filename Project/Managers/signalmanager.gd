#signalmanager.gd (global)
extends Node3D

signal set_spawn_marker(spawner: Marker3D)
signal set_theke_marker(theke: Marker3D)
signal set_waiting_marker_01(waiting01: Marker3D)
signal set_waiting_marker_02(waiting02: Marker3D)
signal set_look_at_marker(look_at: Marker3D)
signal set_customer_exit(exit: Marker3D)
signal set_first_exit_marker(first_exit: Marker3D)

signal update_money(amount: int)
signal update_res_display()

signal switch_menuBtn_visibility(value: bool)
signal toggle_all_ui_for_replicator(value: bool)
signal all_the_main_menu_stuff()

signal on_resume()
signal open_shop()
signal open_order()

signal update_time_left(time: float)
signal update_info_label(info: String)
signal update_info_text_label(info: String)
signal update_ressource_label()
signal update_storage(alk, color, sweet)

signal give_player_stuff(stuff: PackedScene)
signal try_pickup()

signal theke_is_free()
signal waitingslot01_is_free()
signal waitingslot02_is_free()

signal customer_leaves_front()

signal recycle()

signal change_fov()

signal ship_order_display(time_left: String)

signal add_customer(customer:CharacterBody3D)
signal remove_customer(customer:CharacterBody3D)

signal teleport_in()
