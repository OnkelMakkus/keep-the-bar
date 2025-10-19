#generate_resources.gd
@tool
extends EditorScript

const P_LIQUIDS := "res://Project/Data/Liquids"
const P_DRINKS  := "res://Project/Data/Drinks"
const P_MATS    := "res://Project/Data/Mats"
const P_ITEMS   := "res://Project/Data/Replicator"

const PATH_LIQUID          := "res://Project/Data/Liquids/liquid.gd"
const PATH_ING_AMOUNT      := "res://Project/Data/Drinks/ingredient_amount.gd"
const PATH_DRINK_RECIPE    := "res://Project/Data/Drinks/drink_recipe.gd"
const PATH_BASE_MAT        := "res://Project/Data/Mats/rep_base_mat.gd"
const PATH_MAT_AMOUNT      := "res://Project/Data/Mats/rep_mat_amount.gd"
const PATH_REPLICATOR_ITEM := "res://Project/Data/Replicator/replicator_item.gd"

func _mkdir(p: String) -> void:
	var err := DirAccess.make_dir_recursive_absolute(p)
	if err != OK: push_error("mkdir failed: %s (%s)" % [p, str(err)])
	else: print("📁 ensured:", p)

func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK: push_error("save failed: %s (%s)" % [path, str(err)])
	else: print("💾 saved:", path)

func _exists(path: String, label: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("❌ file not found: %s (%s)" % [path, label])
	else:
		print("✅ found:", path)

# ---- Builder-Hilfen -------------------------------------------------

func _ing(liquid: Resource, ml: int, IngredientAmt):
	var ia = IngredientAmt.new()
	ia.liquid = liquid
	ia.amount_ml = ml
	return ia

func _set_ingredients_typed(d: Resource, ings: Array) -> void:
	# d: DrinkRecipe
	d.ingredients.clear()
	for ia in ings:
		d.ingredients.append(ia)

func _ma(mat: Resource, amount: int, RepMatAmount):
	var a = RepMatAmount.new()
	a.mat = mat
	a.amount = amount
	print("Created RepMatAmount:", a, " mat=", mat.id, " amount=", amount)
	return a

func _set_cost_typed(item: Resource, costs: Array) -> void:
	item.cost.clear()
	for c in costs:
		if c and c is Resource:
			item.cost.append(c)
	print("Set cost for", item.id, "->", item.cost.size())

# ---- Hauptlauf ------------------------------------------------------

func _run() -> void:
	print("\n=== Generate Resources ===")
	_mkdir(P_LIQUIDS); _mkdir(P_DRINKS); _mkdir(P_MATS); _mkdir(P_ITEMS)

	_exists(PATH_LIQUID, "Liquid")
	_exists(PATH_ING_AMOUNT, "IngredientAmount")
	_exists(PATH_DRINK_RECIPE, "DrinkRecipe")
	_exists(PATH_BASE_MAT, "RepBaseMat")
	_exists(PATH_MAT_AMOUNT, "RepMatAmount")
	_exists(PATH_REPLICATOR_ITEM, "ReplicatorItem")

	var Liquid          = load(PATH_LIQUID)
	var IngredientAmt   = load(PATH_ING_AMOUNT)
	var DrinkRecipe     = load(PATH_DRINK_RECIPE)
	var RepBaseMat      = load(PATH_BASE_MAT)
	var RepMatAmount    = load(PATH_MAT_AMOUNT)
	var ReplicatorItem  = load(PATH_REPLICATOR_ITEM)
	if not Liquid or not IngredientAmt or not DrinkRecipe or not RepBaseMat or not RepMatAmount or not ReplicatorItem:
		return push_error("⛔ Script konnte nicht geladen werden. Pfade/Dateinamen prüfen.")

	# --- Liquids ---
	var L_rum    = Liquid.new();    L_rum.id="Rum";     L_rum.display_name="Rum"
	var L_whisky = Liquid.new();    L_whisky.id="Whisky"; L_whisky.display_name="Whisky"
	var L_wodka  = Liquid.new();    L_wodka.id="Wodka";  L_wodka.display_name="Wodka"
	var L_beer   = Liquid.new();    L_beer.id="Beer";    L_beer.display_name="Beer"
	_save(L_rum,    "%s/rum.tres"    % P_LIQUIDS)
	_save(L_whisky, "%s/whisky.tres" % P_LIQUIDS)
	_save(L_wodka,  "%s/wodka.tres"  % P_LIQUIDS)
	_save(L_beer,   "%s/beer.tres"   % P_LIQUIDS)

	# --- Drinks ---
	var DR = DrinkRecipe.new()
	var C  = DR.RecipeContainer

	var D_beer   = DrinkRecipe.new()
	D_beer.id="Beer"; D_beer.display_name="Beer"; D_beer.sell_price=3
	D_beer.container=C.BOTTLE; D_beer.ml_tolerance=5; D_beer.allow_extras=false
	_set_ingredients_typed(D_beer,  [ _ing(L_beer, 500, IngredientAmt) ])
	_save(D_beer, "%s/beer_500.tres" % P_DRINKS)

	var D_rum    = DrinkRecipe.new()
	D_rum.id="Rum"; D_rum.display_name="Rum"; D_rum.sell_price=10
	D_rum.container=C.ANY; D_rum.ml_tolerance=5; D_rum.allow_extras=false
	_set_ingredients_typed(D_rum,   [ _ing(L_rum, 40, IngredientAmt) ])
	_save(D_rum, "%s/rum_shot.tres" % P_DRINKS)

	var D_whisky = DrinkRecipe.new()
	D_whisky.id="Whisky"; D_whisky.display_name="Whisky"; D_whisky.sell_price=12
	D_whisky.container=C.ANY; D_whisky.ml_tolerance=5; D_whisky.allow_extras=false
	_set_ingredients_typed(D_whisky,[ _ing(L_whisky, 40, IngredientAmt) ])
	_save(D_whisky, "%s/whisky_shot.tres" % P_DRINKS)

	var D_wodka  = DrinkRecipe.new()
	D_wodka.id="Wodka"; D_wodka.display_name="Wodka"; D_wodka.sell_price=8
	D_wodka.container=C.ANY; D_wodka.ml_tolerance=5; D_wodka.allow_extras=false
	_set_ingredients_typed(D_wodka, [ _ing(L_wodka, 40, IngredientAmt) ])
	_save(D_wodka, "%s/wodka_shot.tres" % P_DRINKS)

	# --- Mats ---
	var M_sweet = RepBaseMat.new(); M_sweet.id="Sweet_Molecules"; M_sweet.display_name="Sweet Molecules"; M_sweet.unit="units"; M_sweet.buy_price=2; M_sweet.buy_amount=100;  M_sweet.current_amount=100
	var M_alco  = RepBaseMat.new(); M_alco.id ="AlcoMol";         M_alco.display_name ="AlcoMol";         M_alco.unit="units"; M_alco.buy_price=4; M_alco.buy_amount=100;  M_alco.current_amount=100
	var M_molor = RepBaseMat.new(); M_molor.id="MolOr";           M_molor.display_name="MolOr";           M_molor.unit="units"; M_molor.buy_price=1; M_molor.buy_amount=100;  M_molor.current_amount=100
	var M_matt  = RepBaseMat.new(); M_matt.id ="Matter";          M_matt.display_name ="Matter";          M_matt.unit="units"; M_matt.buy_price=1; M_matt.buy_amount=1000; M_matt.current_amount=100
	_save(M_sweet, "%s/sweet_molecules.tres" % P_MATS)
	_save(M_alco,  "%s/alcomol.tres"         % P_MATS)
	_save(M_molor, "%s/molor.tres"           % P_MATS)
	_save(M_matt,  "%s/matter.tres"          % P_MATS)

	# --- Items ---
	var I_glass  = ReplicatorItem.new()
	I_glass.id="Glass"; I_glass.display_name="Glass"
	I_glass.scene=load("res://Project/Items/glass.tscn")
	_set_cost_typed(I_glass, [ _ma(M_matt,2,RepMatAmount) ])
	_save(I_glass, "%s/glass.tres" % P_ITEMS)

	var I_rum = ReplicatorItem.new()
	I_rum.id="Rum"; I_rum.display_name="Rum"
	I_rum.scene=load("res://Project/Items/bottle_rum.tscn")
	_set_cost_typed(I_rum, [
		_ma(M_sweet,10,RepMatAmount),
		_ma(M_alco,25,RepMatAmount),
		_ma(M_molor,15,RepMatAmount),
		_ma(M_matt,5,RepMatAmount)
	])
	I_rum.default_liquid=L_rum; I_rum.default_ml=700
	_save(I_rum, "%s/rum.tres" % P_ITEMS)

	var I_whisky = ReplicatorItem.new()
	I_whisky.id="Whisky"; I_whisky.display_name="Whisky"
	I_whisky.scene=load("res://Project/Items/bottle_whisky.tscn")
	_set_cost_typed(I_whisky, [
		_ma(M_sweet,5,RepMatAmount),
		_ma(M_alco,25,RepMatAmount),
		_ma(M_molor,15,RepMatAmount),
		_ma(M_matt,5,RepMatAmount)
	])
	I_whisky.default_liquid=L_whisky; I_whisky.default_ml=700
	_save(I_whisky, "%s/whisky.tres" % P_ITEMS)

	var I_wodka = ReplicatorItem.new()
	I_wodka.id="Wodka"; I_wodka.display_name="Wodka"
	I_wodka.scene=load("res://Project/Items/bottle_wodka.tscn")
	_set_cost_typed(I_wodka, [
		_ma(M_sweet,2,RepMatAmount),
		_ma(M_alco,25,RepMatAmount),
		_ma(M_molor,0,RepMatAmount),
		_ma(M_matt,5,RepMatAmount)
	])
	I_wodka.default_liquid=L_wodka; I_wodka.default_ml=700
	_save(I_wodka, "%s/wodka.tres" % P_ITEMS)

	var I_beer = ReplicatorItem.new()
	I_beer.id="Beer"; I_beer.display_name="Beer"
	I_beer.scene=load("res://Project/Items/beer_bottle.tscn")
	_set_cost_typed(I_beer, [
		_ma(M_sweet,5,RepMatAmount),
		_ma(M_alco,5,RepMatAmount),
		_ma(M_molor,2,RepMatAmount),
		_ma(M_matt,3,RepMatAmount)
	])
	I_beer.default_liquid=L_beer; I_beer.default_ml=500

	print("[GEN] beer BEFORE save -> cost.size=", I_beer.cost.size())
	for c in I_beer.cost:
		print("   -", (c.mat.id if c and c.mat else "<nil>"), c.amount)

	var beer_path := "%s/beer.tres" % P_ITEMS
	_save(I_beer, beer_path)

	# sofort reload & prüfen, was tatsächlich auf Platte liegt
	var I_beer_loaded := load(beer_path) as Resource
	print("[GEN] beer AFTER  save -> cost.size=", (I_beer_loaded.cost.size() if I_beer_loaded else -1))
	if I_beer_loaded:
		for c in I_beer_loaded.cost:
			print("   *", (c.mat.id if c and c.mat else "<nil>"), c.amount)
