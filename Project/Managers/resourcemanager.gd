#resourcemanager.gd (global)
extends Node

@onready var REPLICATOR_RESSOURCES ={
	"Sweet_Molecules": {
		"display_name": "Sweet Molecules",
		"buy_price": 2,
		"buy_amount" : 100,
		"current_amount" : 100,
	},
	"AlcoMol": {
		"display_name": "AlcoMol",
		"buy_price": 4,
		"buy_amount" : 100,
		"current_amount" : 100,
	},
	"MolOr": {
		"display_name": "MolOr",
		"buy_price": 1,
		"buy_amount" : 100,
		"current_amount" : 100,
	},
	"Matter": {
		"display_name": "Matter",
		"buy_price": 1,
		"buy_amount" : 1000,
		"current_amount" : 100,
	}
}

@onready var INGREDIENTS = {
	"Glass": {
		"display_name": "Glass",
		"print_mats" : {
			"Sweet_Molecules" : 0,
			"AlcoMol" : 0,
			"MolOr" : 0,
			"Matter": 2,
		},
		"material": "",
		"res": load("res://Project/Items/glass.tscn"),
	},
	"Rum": {
		"display_name": "Rum",
		"print_mats" : {
			"Sweet_Molecules" : 10,
			"AlcoMol" : 25,
			"MolOr" : 15,
			"Matter": 5,
		},
		"material": load("res://Assets/mats/rum_whisky.tres"),
		"res": load("res://Project/Items/bottle_rum.tscn"),
	},
	"Whisky": {
		"display_name": "Whisky",
		"print_mats" : {
			"Sweet_Molecules" : 5,
			"AlcoMol" : 25,
			"MolOr" : 15,
			"Matter": 5,
		},
		"material": load("res://Assets/mats/rum_whisky.tres"),
		"res": load("res://Project/Items/bottle_whisky.tscn"),
	},
	"Wodka": {
		"display_name": "Wodka",
		"print_mats" : {
			"Sweet_Molecules" : 2,
			"AlcoMol" : 25,
			"MolOr" : 0,
			"Matter": 5,
		},
		"material": load("res://Assets/mats/wodka_water.tres"),
		"res": load("res://Project/Items/bottle_wodka.tscn"),
	},
	"Beer": {
		"display_name": "Beer",
		"print_mats" : {
			"Sweet_Molecules" : 5,
			"AlcoMol" : 5,
			"MolOr" : 2,
			"Matter": 3,
		},
		"material": load("res://Assets/mats/wodka_water.tres"),
		"res": load("res://Project/Items/beer_bottle.tscn"),
	},
	# ... beliebig erweiterbar!
}

@export var RECIPES = {
	"Beer": {
		"display_name": "Beer",
		"sell_price": 3,
		"average_price": 3,
		"ingredients": [
			{"name": "Beer", "amount_ml": 500}
		]
	},
	"Rum": {
		"display_name": "Rum",
		"sell_price": 10,
		"average_price": 10,
		"ingredients": [
			{"name": "Rum", "amount_ml": 40}
		]
	},
	"Whisky": {
		"display_name": "Whisky",
		"sell_price": 12,
		"average_price": 12,
		"ingredients": [
			{"name": "Whisky", "amount_ml": 40}
		]
	},
	"Wodka": {
		"display_name": "Wodka",
		"sell_price": 8,
		"average_price": 8,
		"ingredients": [
			{"name": "Wodka", "amount_ml": 40}
		]
	}
}
