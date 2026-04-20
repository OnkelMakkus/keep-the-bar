#replicator_item.gd
class_name ReplicatorItem
extends Resource

@export var id: String
@export var display_name: String = ""
@export var scene: PackedScene
@export var cost: Array[RepMatAmount] = []

# Optional Defaults für Flaschen/Gläser
@export var default_liquid: Liquid
@export var default_ml: int = 0

# Recycling-Rückgabe (z. B. 0.5 = 50%)
@export var recycle_yield_factor: float = 0.5

# --- NEW: Unlock/Fortschritt ---
@export_range(0, 99, 1) var tier: int = 0
@export var unlock_cost: int = 0
@export var unlocked_by_default: bool = true
@export var prerequisites: PackedStringArray = []
@export var category: String = ""                         # "GLASS","BOTTLE","TOOL" (frei wählbar)
@export var tags: PackedStringArray = []
