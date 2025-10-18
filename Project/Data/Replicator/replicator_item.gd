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
