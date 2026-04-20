# liquid.gd
class_name Liquid
extends Resource

@export var id: String
@export var display_name: String = ""
# Optional (dann kannst du Resourcemanager-Material-Fallback löschen)
@export var material: Material

# --- NEW: Sichtbarkeit/Tier (falls du Liquids einzeln freischalten möchtest) ---
@export_range(0, 99, 1) var tier: int = 0
@export var unlock_cost: int = 0
@export var unlocked_by_default: bool = true
@export var prerequisites: PackedStringArray = []
@export var tags: PackedStringArray = []
