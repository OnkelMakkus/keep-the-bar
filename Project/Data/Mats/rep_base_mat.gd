#base_mat.gd
class_name RepBaseMat
extends Resource

@export var id: String
@export var display_name: String = ""
@export var unit: String = "units"
@export var buy_price: int = 0
@export var buy_amount: int = 0
@export var start_amount: int = 0

@export_range(0, 99, 1) var tier: int = 0                 # 0 = Startcontent
@export var unlock_cost: int = 0                          # Coins für Freischaltung im Shop/Tech
@export var unlocked_by_default: bool = true              # true = sofort verfügbar
@export var prerequisites: PackedStringArray = []         # optional: andere IDs, die nötig sind
@export var tags: PackedStringArray = []                  # z.B. ["grain","bottle","common"]
