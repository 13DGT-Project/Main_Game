## WorkData.gd
## Autoload singleton (Project Settings -> Autoload -> add this as "WorkData").
## Holds content for the supermarket work scene: customer service questions,
## items to use in the restocking minigame, and items to use at checkout.
extends Node

# --- Customer service Q&A (multiple choice, same shape as StudyData questions) ---
var _customer_questions: Array = [
	{"question": "WORKQ_0_PROMPT",
		"options": ["WORKQ_0_OPT0",
			"WORKQ_0_OPT1",
			"WORKQ_0_OPT2",
			"WORKQ_0_OPT3"], "correct": 0},
	{"question": "WORKQ_1_PROMPT",
		"options": ["WORKQ_1_OPT0",
			"WORKQ_1_OPT1",
			"WORKQ_1_OPT2",
			"WORKQ_1_OPT3"], "correct": 0},
	{"question": "WORKQ_2_PROMPT",
		"options": ["WORKQ_2_OPT0",
			"WORKQ_2_OPT1",
			"WORKQ_2_OPT2",
			"WORKQ_2_OPT3"], "correct": 0},
	{"question": "WORKQ_3_PROMPT",
		"options": ["WORKQ_3_OPT0",
			"WORKQ_3_OPT1",
			"WORKQ_3_OPT2",
			"WORKQ_3_OPT3"], "correct": 0},
	{"question": "WORKQ_4_PROMPT",
		"options": ["WORKQ_4_OPT0",
			"WORKQ_4_OPT1",
			"WORKQ_4_OPT2",
			"WORKQ_4_OPT3"], "correct": 0},
	{"question": "WORKQ_5_PROMPT",
		"options": ["WORKQ_5_OPT0",
			"WORKQ_5_OPT1",
			"WORKQ_5_OPT2",
			"WORKQ_5_OPT3"], "correct": 0},
	{"question": "WORKQ_6_PROMPT",
		"options": ["WORKQ_6_OPT0",
			"WORKQ_6_OPT1",
			"WORKQ_6_OPT2",
			"WORKQ_6_OPT3"], "correct": 0},
	{"question": "WORKQ_7_PROMPT",
		"options": ["WORKQ_7_OPT0",
			"WORKQ_7_OPT1",
			"WORKQ_7_OPT2",
			"WORKQ_7_OPT3"], "correct": 0},
	{"question": "WORKQ_8_PROMPT",
		"options": ["WORKQ_8_OPT0",
			"WORKQ_8_OPT1",
			"WORKQ_8_OPT2",
			"WORKQ_8_OPT3"], "correct": 0},
	{"question": "WORKQ_9_PROMPT",
		"options": ["WORKQ_9_OPT0",
			"WORKQ_9_OPT1",
			"WORKQ_9_OPT2",
			"WORKQ_9_OPT3"], "correct": 0},
	{"question": "WORKQ_10_PROMPT",
		"options": ["WORKQ_10_OPT0",
			"WORKQ_10_OPT1",
			"WORKQ_10_OPT2",
			"WORKQ_10_OPT3"], "correct": 0},
	{"question": "WORKQ_11_PROMPT",
		"options": ["WORKQ_11_OPT0",
			"WORKQ_11_OPT1",
			"WORKQ_11_OPT2",
			"WORKQ_11_OPT3"], "correct": 0},
]

# --- Restocking minigame item pool — each has a storage category, since
# where it goes (shelf / fridge / freezer) is now part of the challenge. ---
var _restock_items: Array = [
	# Ambient / shelf-stable
	{"name": "WORKSTOCK_0_NAME", "texture": "res://Backend/Resource/Textures/item_bread.png", "storage": "shelf"},
	{"name": "WORKSTOCK_1_NAME", "texture": "res://Backend/Resource/Textures/item_can.png", "storage": "shelf"},
	{"name": "WORKSTOCK_2_NAME", "texture": "res://Backend/Resource/Textures/item_chips.png", "storage": "shelf"},
	{"name": "WORKSTOCK_3_NAME", "texture": "res://Backend/Resource/Textures/item_apple.png", "storage": "shelf"},
	{"name": "WORKSTOCK_4_NAME", "texture": "res://Backend/Resource/Textures/item_pasta.png", "storage": "shelf"},
	{"name": "WORKSTOCK_5_NAME", "texture": "res://Backend/Resource/Textures/item_rice.png", "storage": "shelf"},
	{"name": "WORKSTOCK_6_NAME", "texture": "res://Backend/Resource/Textures/item_cereal.png", "storage": "shelf"},
	{"name": "WORKSTOCK_7_NAME", "texture": "res://Backend/Resource/Textures/item_biscuits.png", "storage": "shelf"},
	{"name": "WORKSTOCK_8_NAME", "texture": "res://Backend/Resource/Textures/item_bananas.png", "storage": "shelf"},
	{"name": "WORKSTOCK_9_NAME", "texture": "res://Backend/Resource/Textures/item_croissant.png", "storage": "shelf"},
	# Chilled
	{"name": "WORKSTOCK_10_NAME", "texture": "res://Backend/Resource/Textures/item_milk.png", "storage": "fridge"},
	{"name": "WORKSTOCK_11_NAME", "texture": "res://Backend/Resource/Textures/item_cheese.png", "storage": "fridge"},
	{"name": "WORKSTOCK_12_NAME", "texture": "res://Backend/Resource/Textures/item_yoghurt.png", "storage": "fridge"},
	{"name": "WORKSTOCK_13_NAME", "texture": "res://Backend/Resource/Textures/item_butter.png", "storage": "fridge"},
	{"name": "WORKSTOCK_14_NAME", "texture": "res://Backend/Resource/Textures/item_sausage.png", "storage": "fridge"},
	{"name": "WORKSTOCK_15_NAME", "texture": "res://Backend/Resource/Textures/item_mince.png", "storage": "fridge"},
	{"name": "WORKSTOCK_16_NAME", "texture": "res://Backend/Resource/Textures/item_fresh_fish.png", "storage": "fridge"},
	# Frozen
	{"name": "WORKSTOCK_17_NAME", "texture": "res://Backend/Resource/Textures/item_frozen_peas.png", "storage": "freezer"},
	{"name": "WORKSTOCK_18_NAME", "texture": "res://Backend/Resource/Textures/item_ice_cream.png", "storage": "freezer"},
	{"name": "WORKSTOCK_19_NAME", "texture": "res://Backend/Resource/Textures/item_frozen_chips.png", "storage": "freezer"},
	{"name": "WORKSTOCK_20_NAME", "texture": "res://Backend/Resource/Textures/item_fish_fingers.png", "storage": "freezer"},
]

# Checkout minigame item pool — each has a checkout_type that decides how
# you actually process it: "scan" (drag across the scanner), "weigh" (type
# the kg for loose produce), or "lookup" (no barcode, type the item's name). --
var _checkout_items: Array = [
	# Barcoded — drag onto the scanner
	{"name": "WORKTILL_0_NAME", "texture": "res://Backend/Resource/Textures/item_milk.png", "price": 4.50, "checkout_type": "scan"},
	{"name": "WORKTILL_1_NAME", "texture": "res://Backend/Resource/Textures/item_bread.png", "price": 3.20, "checkout_type": "scan"},
	{"name": "WORKTILL_2_NAME", "texture": "res://Backend/Resource/Textures/item_can.png", "price": 2.10, "checkout_type": "scan"},
	{"name": "WORKTILL_3_NAME", "texture": "res://Backend/Resource/Textures/item_chips.png", "price": 4.00, "checkout_type": "scan"},
	{"name": "WORKTILL_4_NAME", "texture": "res://Backend/Resource/Textures/item_cheese.png", "price": 7.50, "checkout_type": "scan"},
	{"name": "WORKTILL_5_NAME", "texture": "res://Backend/Resource/Textures/item_frozen_peas.png", "price": 3.00, "checkout_type": "scan"},
	{"name": "WORKTILL_6_NAME", "texture": "res://Backend/Resource/Textures/item_ice_cream.png", "price": 6.50, "checkout_type": "scan"},
	{"name": "WORKTILL_7_NAME", "texture": "res://Backend/Resource/Textures/item_sausage.png", "price": 8.00, "checkout_type": "scan"},
	# Loose produce — weigh it
	{"name": "WORKTILL_8_NAME", "texture": "res://Backend/Resource/Textures/item_apple.png", "price": 5.80, "checkout_type": "weigh"},
	{"name": "WORKTILL_9_NAME", "texture": "res://Backend/Resource/Textures/item_bananas.png", "price": 3.90, "checkout_type": "weigh"},
	{"name": "WORKTILL_10_NAME", "texture": "res://Backend/Resource/Textures/item_fresh_fish.png", "price": 24.00, "checkout_type": "weigh"},
	{"name": "WORKTILL_11_NAME", "texture": "res://Backend/Resource/Textures/item_mince.png", "price": 16.50, "checkout_type": "weigh"},
	# No barcode — look it up by name
	{"name": "WORKTILL_12_NAME", "texture": "res://Backend/Resource/Textures/item_croissant.png", "price": 3.50, "checkout_type": "lookup"},
	{"name": "WORKTILL_13_NAME", "texture": "res://Backend/Resource/Textures/item_meat.png", "price": 6.00, "checkout_type": "lookup"},
	{"name": "WORKTILL_14_NAME", "texture": "res://Backend/Resource/Textures/item_cake.png", "price": 22.00, "checkout_type": "lookup"},
]


## Item pools hold localisation keys in "name"; this hands back a copy with
## the name in the active language.
func _translated(item: Dictionary) -> Dictionary:
	var out: Dictionary = item.duplicate()
	out["name"] = tr(str(item.name))
	return out


## For the lookup minigame: a few plausible wrong names to sit alongside the
## right one, so the player picks from a shortlist instead of typing blind.
func get_lookup_options(correct_name: String, count: int = 4) -> Array:
	# correct_name arrives already translated (from get_checkout_round), so the
	# pool is translated too — everything compared here is in the same language.
	var pool: Array = []
	for item in _checkout_items:
		var item_name: String = tr(str(item.name))
		if item_name != correct_name and not item_name in pool:
			pool.append(item_name)
	pool.shuffle()
	var options: Array = [correct_name]
	for candidate in pool:
		if options.size() >= count:
			break
		options.append(candidate)
	options.shuffle()
	return options


#Bakery minigame item pool: things you're baking
var _bakery_items: Array = [
	{"name": "WORKBAKE_0_NAME", "texture": "res://Backend/Resource/Textures/item_bread.png"},
	{"name": "WORKBAKE_1_NAME", "texture": "res://Backend/Resource/Textures/item_croissant.png"},
	{"name": "WORKBAKE_2_NAME", "texture": "res://Backend/Resource/Textures/item_cake.png"},
]

# Deli (meat & fish counter) item pool, same shape as restock items 
var _deli_items: Array = [
	{"name": "WORKDELI_0_NAME", "texture": "res://Backend/Resource/Textures/item_meat.png"},
	{"name": "WORKDELI_1_NAME", "texture": "res://Backend/Resource/Textures/item_fish.png"},
	{"name": "WORKDELI_2_NAME", "texture": "res://Backend/Resource/Textures/item_sausage.png"},
]


## Each item gets a "prep" step then a "cook" step in sequence (knead the
## dough, then bake it) — a proper little recipe rather than a random pick.
## `item_count` is how many separate items you'll make (so the actual number
## of steps in the round is item_count * 2).
func get_bakery_round(item_count: int = 4) -> Array:
	var round_items: Array = []
	for i in item_count:
		var item: Dictionary = _translated(_bakery_items[randi() % _bakery_items.size()])
		var knead_step: Dictionary = item.duplicate()
		knead_step["kind"] = "knead"
		var bake_step: Dictionary = item.duplicate()
		bake_step["kind"] = "bake"
		round_items.append(knead_step)
		round_items.append(bake_step)
	return round_items


func get_deli_round(item_count: int = 5) -> Array:
	var round_items: Array = []
	for i in item_count:
		var item: Dictionary = _translated(_deli_items[randi() % _deli_items.size()])
		var chop_step: Dictionary = item.duplicate()
		chop_step["kind"] = "chop"
		var slice_step: Dictionary = item.duplicate()
		slice_step["kind"] = "slice"
		round_items.append(chop_step)
		round_items.append(slice_step)
	return round_items


func get_customer_questions(count: int = 3) -> Array:
	var pool: Array = _customer_questions.duplicate(true)
	pool.shuffle()
	var selected: Array = pool.slice(0, min(count, pool.size()))
	var result: Array = []
	for q in selected:
		# Same fix as StudyData — every customer question was authored with the
		# right answer first, so shuffle and remap the correct index.
		result.append(StudyData.shuffle_question(q))
	return result


func get_restock_round(count: int = 5) -> Array:
	# Restocking rounds can repeat items (a real shelf needs many of the same product),
	# so sample with replacement rather than shuffling a fixed pool.
	var round_items: Array = []
	for i in count:
		round_items.append(_translated(_restock_items[randi() % _restock_items.size()]))
	return round_items


func get_checkout_round(count: int = 5) -> Array:
	var round_items: Array = []
	for i in count:
		var item: Dictionary = _translated(_checkout_items[randi() % _checkout_items.size()])
		if item.checkout_type == "weigh":
			item["target_weight"] = snappedf(randf_range(0.2, 1.8), 0.01)
		round_items.append(item)
	return round_items


#Shop menus
# cost / energy / thirst / sanity. Kept here so the Canteen and Dairy scenes
# share one list instead of each hardcoding their own.

const CANTEEN_MENU := [
	{"label": "FOOD_MINCE_CHEESE_PIE", "cost": 4.50, "energy": 16.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "FOOD_STEAK_PIE", "cost": 5.00, "energy": 18.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "FOOD_SAUSAGE_ROLL", "cost": 3.50, "energy": 12.0, "thirst": -2.0, "sanity": 3.0},
	{"label": "FOOD_CHEESE_TOASTIE", "cost": 3.00, "energy": 11.0, "thirst": 0.0, "sanity": 3.0},
	{"label": "FOOD_HAM_SALAD_SANDWICH", "cost": 5.50, "energy": 14.0, "thirst": 4.0, "sanity": 4.0},
	{"label": "FOOD_CHICKEN_WRAP", "cost": 6.50, "energy": 18.0, "thirst": 3.0, "sanity": 5.0},
	{"label": "FOOD_SUSHI_3_PACK", "cost": 6.00, "energy": 15.0, "thirst": 3.0, "sanity": 5.0},
	{"label": "FOOD_BUTTER_CHICKEN_RICE", "cost": 8.00, "energy": 26.0, "thirst": 0.0, "sanity": 7.0},
	{"label": "FOOD_MAC_CHEESE", "cost": 6.00, "energy": 22.0, "thirst": -2.0, "sanity": 5.0},
	{"label": "FOOD_HOT_CHIPS", "cost": 4.00, "energy": 15.0, "thirst": -4.0, "sanity": 6.0},
	{"label": "FOOD_WEDGES_SOUR_CREAM", "cost": 5.00, "energy": 17.0, "thirst": -3.0, "sanity": 6.0},
	{"label": "FOOD_NACHOS", "cost": 6.50, "energy": 20.0, "thirst": -4.0, "sanity": 6.0},
	{"label": "FOOD_FRUIT_SALAD", "cost": 4.00, "energy": 8.0, "thirst": 10.0, "sanity": 3.0},
	{"label": "FOOD_YOGHURT_MUESLI", "cost": 4.50, "energy": 10.0, "thirst": 5.0, "sanity": 3.0},
	{"label": "FOOD_BANANA", "cost": 1.50, "energy": 6.0, "thirst": 3.0, "sanity": 1.0},
	{"label": "FOOD_MUFFIN", "cost": 3.00, "energy": 10.0, "thirst": -1.0, "sanity": 4.0},
	{"label": "FOOD_COOKIE", "cost": 2.00, "energy": 7.0, "thirst": -1.0, "sanity": 4.0},
	{"label": "FOOD_MILKSHAKE", "cost": 4.50, "energy": 10.0, "thirst": 14.0, "sanity": 6.0},
	{"label": "FOOD_BOTTLED_WATER", "cost": 2.00, "energy": 0.0, "thirst": 30.0, "sanity": 1.0},
	{"label": "FOOD_JUICE_BOX", "cost": 2.50, "energy": 4.0, "thirst": 20.0, "sanity": 2.0},
	{"label": "FOOD_POWERADE", "cost": 4.00, "energy": 12.0, "thirst": 22.0, "sanity": 2.0},
	{"label": "FOOD_HOT_CHOCOLATE", "cost": 3.50, "energy": 8.0, "thirst": 10.0, "sanity": 7.0},
]

const DAIRY_MENU := [
	{"label": "FOOD_MIXED_LOLLIES_BAG", "cost": 3.00, "energy": 9.0, "thirst": -3.0, "sanity": 8.0},
	{"label": "FOOD_PINEAPPLE_LUMPS", "cost": 3.50, "energy": 10.0, "thirst": -2.0, "sanity": 8.0},
	{"label": "FOOD_JET_PLANES", "cost": 3.00, "energy": 9.0, "thirst": -2.0, "sanity": 7.0},
	{"label": "FOOD_PARTY_MIX", "cost": 4.00, "energy": 11.0, "thirst": -3.0, "sanity": 8.0},
	{"label": "FOOD_CHOCOLATE_BAR", "cost": 3.50, "energy": 13.0, "thirst": -2.0, "sanity": 7.0},
	{"label": "FOOD_WHITTAKER_S_BLOCK", "cost": 5.50, "energy": 20.0, "thirst": -3.0, "sanity": 10.0},
	{"label": "FOOD_ICE_BLOCK", "cost": 2.50, "energy": 5.0, "thirst": 12.0, "sanity": 6.0},
	{"label": "FOOD_ICE_CREAM_CONE", "cost": 4.50, "energy": 12.0, "thirst": 6.0, "sanity": 9.0},
	{"label": "FOOD_HOKEY_POKEY_TUB", "cost": 6.00, "energy": 16.0, "thirst": 4.0, "sanity": 10.0},
	{"label": "FOOD_CHIPPIES_SMALL", "cost": 2.50, "energy": 8.0, "thirst": -4.0, "sanity": 5.0},
	{"label": "FOOD_CHIPPIES_LARGE", "cost": 4.50, "energy": 14.0, "thirst": -6.0, "sanity": 6.0},
	{"label": "FOOD_TWISTIES", "cost": 3.00, "energy": 9.0, "thirst": -4.0, "sanity": 5.0},
	{"label": "FOOD_MEAT_PIE", "cost": 4.50, "energy": 17.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "FOOD_SAUSAGE_ROLL", "cost": 3.50, "energy": 13.0, "thirst": -2.0, "sanity": 3.0},
	{"label": "FOOD_TOASTIE", "cost": 4.00, "energy": 13.0, "thirst": 0.0, "sanity": 4.0},
	{"label": "FOOD_ENERGY_DRINK", "cost": 5.00, "energy": 26.0, "thirst": 8.0, "sanity": -3.0},
	{"label": "FOOD_FIZZY_DRINK", "cost": 3.50, "energy": 10.0, "thirst": 16.0, "sanity": 4.0},
	{"label": "FOOD_BOTTLED_WATER", "cost": 2.00, "energy": 0.0, "thirst": 30.0, "sanity": 1.0},
	{"label": "FOOD_FLAVOURED_MILK", "cost": 4.00, "energy": 14.0, "thirst": 18.0, "sanity": 6.0},
	{"label": "FOOD_BREAD_LOAF", "cost": 4.00, "energy": 10.0, "thirst": -1.0, "sanity": 1.0},
	{"label": "FOOD_MILK_2L", "cost": 5.00, "energy": 8.0, "thirst": 20.0, "sanity": 1.0},
	{"label": "FOOD_INSTANT_NOODLES", "cost": 1.50, "energy": 11.0, "thirst": -5.0, "sanity": 2.0},
]


## Random selection from a menu, so the shop shows a different range each visit
## rather than the same handful every time.
static func pick_menu(menu: Array, count: int = 6) -> Array:
	var pool: Array = menu.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))
