# drink_recipe.gd
class_name DrinkRecipe
extends Resource

enum RecipeContainer { ANY, GLASS, BOTTLE }   # wichtig: NICHT "Container" nennen

@export var id: String
@export var display_name: String = ""
@export var sell_price: int = 0
@export_enum("ANY", "GLASS", "BOTTLE") var container: int = RecipeContainer.ANY
@export var ml_tolerance: int = 5
@export var allow_extras: bool = false
@export var ingredients: Array[IngredientAmount] = []
@export var spoil_time: float
