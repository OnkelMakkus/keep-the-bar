# drink_recipe.gd
class_name DrinkRecipe
extends Resource

enum RecipeContainer { ANY, GLASS, BOTTLE }   # wichtig: NICHT "Container" nennen

@export var id: String
@export var display_name: String = ""
@export var sell_price: int = 0
@export_enum("ANY", "GLASS", "BOTTLE") var container: int = RecipeContainer.ANY
@export var ingredients: Array[IngredientAmount] = []
@export var spoil_time: float

# --- NEW: Unlock/Fortschritt ---
@export_range(0, 99, 1) var tier: int = 0
@export var unlock_cost: int = 0
@export var unlocked_by_default: bool = false             # Rezepte i.d.R. gesperrt
@export var prerequisites: PackedStringArray = []         # z.B. benötigte Item/Mats/Recipe-IDs
@export var tags: PackedStringArray = []                  # "classic","whisky","sour", ...
# Optional Balancing:
@export_range(0,100,1) var difficulty: int = 0           # für UI/XP/Sterne etc.
