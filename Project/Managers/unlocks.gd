# Unlocks.gd
extends Node
signal unlocked(kind: String, id: String)

# ================================
# Laufzeitdaten
# ================================
var coins: int = 0
var unlocked_mats: Dictionary = {}    # id -> true
var unlocked_items: Dictionary = {}
var unlocked_drinks: Dictionary = {}

# ================================
# Init / Reset
# ================================
func _ready() -> void:
	reset_for_new_game()  # optional direkt beim Start

func reset_for_new_game() -> void:
	coins = 0
	unlocked_mats.clear()
	unlocked_items.clear()
	unlocked_drinks.clear()

	# Basis-Inhalte aus den DBs aktivieren
	for m in ReplicatorDB.MATS.values():
		if m.unlocked_by_default:
			unlocked_mats[m.id] = true

	for it in ReplicatorDB.ITEMS.values():
		if it.unlocked_by_default:
			unlocked_items[it.id] = true

	if Engine.has_singleton("DrinkDB"):
		for d in DrinkDB.RECIPES.values():
			if d.unlocked_by_default:
				unlocked_drinks[d.id] = true

	print("[Unlocks] Initialized new game.")

# ================================
# Zugriff
# ================================
func is_unlocked(kind: String, id: String) -> bool:
	match kind:
		"mat":   return unlocked_mats.has(id)
		"item":  return unlocked_items.has(id)
		"drink": return unlocked_drinks.has(id)
		_:       return false

func unlock(kind: String, res: Resource) -> void:
	if res == null or res.id == "": return
	match kind:
		"mat":   unlocked_mats[res.id] = true
		"item":  unlocked_items[res.id] = true
		"drink": unlocked_drinks[res.id] = true
	emit_signal("unlocked", kind, res.id)
	print("[Unlocks] Unlocked:", kind, res.id)

func get_all_unlocked(kind: String) -> Array:
	match kind:
		"mat":   return unlocked_mats.keys()
		"item":  return unlocked_items.keys()
		"drink": return unlocked_drinks.keys()
		_:       return []

# ================================
# Shop / Coins Logik (optional)
# ================================
func can_afford(cost: int) -> bool:
	return coins >= cost

func spend(amount: int) -> bool:
	if amount > coins:
		return false
	coins -= amount
	return true

func add_coins(amount: int) -> void:
	coins += max(0, amount)
