@tool
extends EditorPlugin

## === Bar Resource Editor Plugin ===
##
## Registriert ein Dock-Panel im Editor, über das du deine
## Bar-Ressourcen (Mats, Liquids, Items, Drinks) anlegen kannst.
## Das eigentliche UI liegt in: res://addons/bar_resource_editor/bar_resource_panel.tscn
##
## Autor: ChatGPT / Markus-Version
## Kompatibel mit Godot 4.5+

var panel: VBoxContainer

func _enter_tree() -> void:
	print("📦 [BarResourceEditor] wird geladen ...")
	
	# Panel-Szeneninstanz laden
	var panel_scene := preload("res://addons/bar_resource_editor/bar_resource_panel.tscn")
	panel = panel_scene.instantiate()

	# EditorInterface-Referenz übergeben (damit das Panel Ressourcen öffnen kann)
	if "editor_interface" in panel:
		panel.editor_interface = get_editor_interface()

	# In Editor-Dock rechts oben einfügen
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)
	print("✅ BarResourceEditor aktiv (Dock rechts oben)")

func _exit_tree() -> void:
	# Aufräumen beim Entfernen/Deaktivieren
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
		panel = null
	print("🧹 [BarResourceEditor] entfernt.")
