## WorkData.gd
## Autoload singleton (Project Settings -> Autoload -> add this as "WorkData").
##
## Holds content for the supermarket work scene: customer service questions,
## items to use in the restocking minigame, and items to use at checkout.
extends Node

# --- Customer service Q&A (multiple choice, same shape as StudyData questions) ---
var _customer_questions: Array = [
	{"question": "A customer asks: \"Excuse me, where can I find the milk?\"",
		"options": ["\"It's in the dairy aisle, near the back on the left.\"",
			"\"I don't know, I don't work here.\"",
			"\"Check the internet.\"",
			"\"We don't sell milk.\""], "correct": 0},
	{"question": "A customer asks: \"Do you have any gluten-free bread?\"",
		"options": ["\"Yes, it's usually on the health-food shelf near the bakery.\"",
			"\"No idea what gluten is.\"",
			"\"We only sell normal bread.\"",
			"\"You'll have to ask someone else.\""], "correct": 0},
	{"question": "A customer says: \"This yoghurt is past its use-by date, can I still buy it?\"",
		"options": ["\"Let me swap that for a fresh one for you.\"",
			"\"Sure, it'll probably be fine.\"",
			"\"That's not my problem.\"",
			"\"Just eat it quickly.\""], "correct": 0},
	{"question": "A customer asks: \"Can I pay with card here, or is it cash only?\"",
		"options": ["\"Card's fine — eftpos, credit, or contactless all work.\"",
			"\"Cash only, sorry.\"",
			"\"We don't take payment here.\"",
			"\"Only cheques.\""], "correct": 0},
	{"question": "A customer asks: \"Is this coupon still valid? It says it expired yesterday.\"",
		"options": ["\"Sorry, it's expired — I can't apply it, but let me check for a current one.\"",
			"\"Doesn't matter, I'll use it anyway.\"",
			"\"Coupons never expire.\"",
			"\"I'll just give you the discount for free.\""], "correct": 0},
	{"question": "A customer asks: \"Do you price-match other supermarkets?\"",
		"options": ["\"I'm not sure, let me check with a supervisor for you.\"",
			"\"Yes, always, no matter what.\"",
			"\"Absolutely not, don't ask again.\"",
			"\"We don't have a policy on that, figure it out yourself.\""], "correct": 0},
	{"question": "A customer asks: \"Where are the trolleys?\"",
		"options": ["\"Right at the front entrance, next to the baskets.\"",
			"\"We don't have trolleys.\"",
			"\"Somewhere out the back.\"",
			"\"You'll have to carry everything.\""], "correct": 0},
	{"question": "A customer is upset a product is out of stock. What's the best response?",
		"options": ["\"Sorry about that — I can check if we have more coming, or suggest an alternative.\"",
			"\"Not my problem.\"",
			"\"We're always out of everything.\"",
			"\"Try a different supermarket.\""], "correct": 0},
	{"question": "A customer asks: \"Can I return this item without a receipt?\"",
		"options": ["\"It depends on the item — let me check our return policy for you.\"",
			"\"No returns, ever, for any reason.\"",
			"\"Sure, just take whatever you want.\"",
			"\"Receipts don't matter at all.\""], "correct": 0},
	{"question": "A customer asks: \"What time do you close tonight?\"",
		"options": ["\"We close at 9pm tonight.\"",
			"\"I have no idea.\"",
			"\"We're open 24 hours, always.\"",
			"\"Ask someone else.\""], "correct": 0},
	{"question": "An elderly customer asks for help reaching an item on a high shelf.",
		"options": ["\"Of course, let me grab that for you.\"",
			"\"You'll have to find someone taller.\"",
			"\"That's not part of my job.\"",
			"\"Just climb the shelf.\""], "correct": 0},
	{"question": "A customer asks: \"Is this on special this week?\"",
		"options": ["\"Let me check the shelf tag / scan it to confirm the price for you.\"",
			"\"Everything is always on special.\"",
			"\"I wouldn't know, guess.\"",
			"\"Nothing is ever on special.\""], "correct": 0},
]

# --- Restocking minigame item pool — each has a storage category, since
# where it goes (shelf / fridge / freezer) is now part of the challenge. ---
var _restock_items: Array = [
	# Ambient / shelf-stable
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png", "storage": "shelf"},
	{"name": "Canned Beans", "texture": "res://Backend/Resource/Textures/item_can.png", "storage": "shelf"},
	{"name": "Chips", "texture": "res://Backend/Resource/Textures/item_chips.png", "storage": "shelf"},
	{"name": "Apples", "texture": "res://Backend/Resource/Textures/item_apple.png", "storage": "shelf"},
	{"name": "Pasta", "texture": "res://Backend/Resource/Textures/item_pasta.png", "storage": "shelf"},
	{"name": "Rice", "texture": "res://Backend/Resource/Textures/item_rice.png", "storage": "shelf"},
	{"name": "Cereal", "texture": "res://Backend/Resource/Textures/item_cereal.png", "storage": "shelf"},
	{"name": "Biscuits", "texture": "res://Backend/Resource/Textures/item_biscuits.png", "storage": "shelf"},
	{"name": "Bananas", "texture": "res://Backend/Resource/Textures/item_bananas.png", "storage": "shelf"},
	{"name": "Croissant", "texture": "res://Backend/Resource/Textures/item_croissant.png", "storage": "shelf"},
	# Chilled
	{"name": "Milk", "texture": "res://Backend/Resource/Textures/item_milk.png", "storage": "fridge"},
	{"name": "Cheese", "texture": "res://Backend/Resource/Textures/item_cheese.png", "storage": "fridge"},
	{"name": "Yoghurt", "texture": "res://Backend/Resource/Textures/item_yoghurt.png", "storage": "fridge"},
	{"name": "Butter", "texture": "res://Backend/Resource/Textures/item_butter.png", "storage": "fridge"},
	{"name": "Sausages", "texture": "res://Backend/Resource/Textures/item_sausage.png", "storage": "fridge"},
	{"name": "Mince", "texture": "res://Backend/Resource/Textures/item_mince.png", "storage": "fridge"},
	{"name": "Fresh Fish", "texture": "res://Backend/Resource/Textures/item_fresh_fish.png", "storage": "fridge"},
	# Frozen
	{"name": "Frozen Peas", "texture": "res://Backend/Resource/Textures/item_frozen_peas.png", "storage": "freezer"},
	{"name": "Ice Cream", "texture": "res://Backend/Resource/Textures/item_ice_cream.png", "storage": "freezer"},
	{"name": "Frozen Chips", "texture": "res://Backend/Resource/Textures/item_frozen_chips.png", "storage": "freezer"},
	{"name": "Fish Fingers", "texture": "res://Backend/Resource/Textures/item_fish_fingers.png", "storage": "freezer"},
]

# --- Checkout minigame item pool — each has a checkout_type that decides how
# you actually process it: "scan" (drag across the scanner), "weigh" (type
# the kg for loose produce), or "lookup" (no barcode, type the item's name). --
var _checkout_items: Array = [
	# Barcoded — drag onto the scanner
	{"name": "Milk", "texture": "res://Backend/Resource/Textures/item_milk.png", "price": 4.50, "checkout_type": "scan"},
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png", "price": 3.20, "checkout_type": "scan"},
	{"name": "Canned Beans", "texture": "res://Backend/Resource/Textures/item_can.png", "price": 2.10, "checkout_type": "scan"},
	{"name": "Chips", "texture": "res://Backend/Resource/Textures/item_chips.png", "price": 4.00, "checkout_type": "scan"},
	{"name": "Cheese", "texture": "res://Backend/Resource/Textures/item_cheese.png", "price": 7.50, "checkout_type": "scan"},
	{"name": "Frozen Peas", "texture": "res://Backend/Resource/Textures/item_frozen_peas.png", "price": 3.00, "checkout_type": "scan"},
	{"name": "Ice Cream", "texture": "res://Backend/Resource/Textures/item_ice_cream.png", "price": 6.50, "checkout_type": "scan"},
	{"name": "Sausages", "texture": "res://Backend/Resource/Textures/item_sausage.png", "price": 8.00, "checkout_type": "scan"},
	# Loose produce — weigh it
	{"name": "Apples", "texture": "res://Backend/Resource/Textures/item_apple.png", "price": 5.80, "checkout_type": "weigh"},
	{"name": "Bananas", "texture": "res://Backend/Resource/Textures/item_bananas.png", "price": 3.90, "checkout_type": "weigh"},
	{"name": "Fresh Fish", "texture": "res://Backend/Resource/Textures/item_fresh_fish.png", "price": 24.00, "checkout_type": "weigh"},
	{"name": "Mince", "texture": "res://Backend/Resource/Textures/item_mince.png", "price": 16.50, "checkout_type": "weigh"},
	# No barcode — look it up by name
	{"name": "Croissant", "texture": "res://Backend/Resource/Textures/item_croissant.png", "price": 3.50, "checkout_type": "lookup"},
	{"name": "Meat", "texture": "res://Backend/Resource/Textures/item_meat.png", "price": 6.00, "checkout_type": "lookup"},
	{"name": "Cake", "texture": "res://Backend/Resource/Textures/item_cake.png", "price": 22.00, "checkout_type": "lookup"},
]


## For the lookup minigame: a few plausible wrong names to sit alongside the
## right one, so the player picks from a shortlist instead of typing blind.
func get_lookup_options(correct_name: String, count: int = 4) -> Array:
	var pool: Array = []
	for item in _checkout_items:
		if item.name != correct_name and not item.name in pool:
			pool.append(item.name)
	pool.shuffle()
	var options: Array = [correct_name]
	for candidate in pool:
		if options.size() >= count:
			break
		options.append(candidate)
	options.shuffle()
	return options


# --- Bakery minigame item pool: things you're baking, used with the timing QTE ---
var _bakery_items: Array = [
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png"},
	{"name": "Croissant", "texture": "res://Backend/Resource/Textures/item_croissant.png"},
	{"name": "Cake", "texture": "res://Backend/Resource/Textures/item_cake.png"},
]

# --- Deli (meat & fish counter) item pool, same shape as restock items ---
var _deli_items: Array = [
	{"name": "Meat", "texture": "res://Backend/Resource/Textures/item_meat.png"},
	{"name": "Fish", "texture": "res://Backend/Resource/Textures/item_fish.png"},
	{"name": "Sausages", "texture": "res://Backend/Resource/Textures/item_sausage.png"},
]


## Each item gets a "prep" step then a "cook" step in sequence (knead the
## dough, then bake it) — a proper little recipe rather than a random pick.
## `item_count` is how many separate items you'll make (so the actual number
## of steps in the round is item_count * 2).
func get_bakery_round(item_count: int = 4) -> Array:
	var round_items: Array = []
	for i in item_count:
		var item: Dictionary = _bakery_items[randi() % _bakery_items.size()]
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
		var item: Dictionary = _deli_items[randi() % _deli_items.size()]
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
		var shuffled: Dictionary = q.duplicate(true)
		var correct_text: String = shuffled.options[shuffled.correct]
		shuffled.options.shuffle()
		shuffled.correct = shuffled.options.find(correct_text)
		result.append(shuffled)
	return result


func get_restock_round(count: int = 5) -> Array:
	# Restocking rounds can repeat items (a real shelf needs many of the same product),
	# so sample with replacement rather than shuffling a fixed pool.
	var round_items: Array = []
	for i in count:
		round_items.append(_restock_items[randi() % _restock_items.size()])
	return round_items


func get_checkout_round(count: int = 5) -> Array:
	var round_items: Array = []
	for i in count:
		var item: Dictionary = _checkout_items[randi() % _checkout_items.size()].duplicate()
		if item.checkout_type == "weigh":
			item["target_weight"] = snappedf(randf_range(0.2, 1.8), 0.01)
		round_items.append(item)
	return round_items


# --- Shop menus ---------------------------------------------------------------
# cost / energy / thirst / sanity. Kept here so the Canteen and Dairy scenes
# share one list instead of each hardcoding their own.

const CANTEEN_MENU := [
	{"label": "Mince & Cheese Pie", "cost": 4.50, "energy": 16.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "Steak Pie", "cost": 5.00, "energy": 18.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "Sausage Roll", "cost": 3.50, "energy": 12.0, "thirst": -2.0, "sanity": 3.0},
	{"label": "Cheese Toastie", "cost": 3.00, "energy": 11.0, "thirst": 0.0, "sanity": 3.0},
	{"label": "Ham & Salad Sandwich", "cost": 5.50, "energy": 14.0, "thirst": 4.0, "sanity": 4.0},
	{"label": "Chicken Wrap", "cost": 6.50, "energy": 18.0, "thirst": 3.0, "sanity": 5.0},
	{"label": "Sushi (3 pack)", "cost": 6.00, "energy": 15.0, "thirst": 3.0, "sanity": 5.0},
	{"label": "Butter Chicken & Rice", "cost": 8.00, "energy": 26.0, "thirst": 0.0, "sanity": 7.0},
	{"label": "Mac & Cheese", "cost": 6.00, "energy": 22.0, "thirst": -2.0, "sanity": 5.0},
	{"label": "Hot Chips", "cost": 4.00, "energy": 15.0, "thirst": -4.0, "sanity": 6.0},
	{"label": "Wedges & Sour Cream", "cost": 5.00, "energy": 17.0, "thirst": -3.0, "sanity": 6.0},
	{"label": "Nachos", "cost": 6.50, "energy": 20.0, "thirst": -4.0, "sanity": 6.0},
	{"label": "Fruit Salad", "cost": 4.00, "energy": 8.0, "thirst": 10.0, "sanity": 3.0},
	{"label": "Yoghurt & Muesli", "cost": 4.50, "energy": 10.0, "thirst": 5.0, "sanity": 3.0},
	{"label": "Banana", "cost": 1.50, "energy": 6.0, "thirst": 3.0, "sanity": 1.0},
	{"label": "Muffin", "cost": 3.00, "energy": 10.0, "thirst": -1.0, "sanity": 4.0},
	{"label": "Cookie", "cost": 2.00, "energy": 7.0, "thirst": -1.0, "sanity": 4.0},
	{"label": "Milkshake", "cost": 4.50, "energy": 10.0, "thirst": 14.0, "sanity": 6.0},
	{"label": "Bottled Water", "cost": 2.00, "energy": 0.0, "thirst": 30.0, "sanity": 1.0},
	{"label": "Juice Box", "cost": 2.50, "energy": 4.0, "thirst": 20.0, "sanity": 2.0},
	{"label": "Powerade", "cost": 4.00, "energy": 12.0, "thirst": 22.0, "sanity": 2.0},
	{"label": "Hot Chocolate", "cost": 3.50, "energy": 8.0, "thirst": 10.0, "sanity": 7.0},
]

const DAIRY_MENU := [
	{"label": "Mixed Lollies (bag)", "cost": 3.00, "energy": 9.0, "thirst": -3.0, "sanity": 8.0},
	{"label": "Pineapple Lumps", "cost": 3.50, "energy": 10.0, "thirst": -2.0, "sanity": 8.0},
	{"label": "Jet Planes", "cost": 3.00, "energy": 9.0, "thirst": -2.0, "sanity": 7.0},
	{"label": "Party Mix", "cost": 4.00, "energy": 11.0, "thirst": -3.0, "sanity": 8.0},
	{"label": "Chocolate Bar", "cost": 3.50, "energy": 13.0, "thirst": -2.0, "sanity": 7.0},
	{"label": "Whittaker's Block", "cost": 5.50, "energy": 20.0, "thirst": -3.0, "sanity": 10.0},
	{"label": "Ice Block", "cost": 2.50, "energy": 5.0, "thirst": 12.0, "sanity": 6.0},
	{"label": "Ice Cream Cone", "cost": 4.50, "energy": 12.0, "thirst": 6.0, "sanity": 9.0},
	{"label": "Hokey Pokey Tub", "cost": 6.00, "energy": 16.0, "thirst": 4.0, "sanity": 10.0},
	{"label": "Chippies (small)", "cost": 2.50, "energy": 8.0, "thirst": -4.0, "sanity": 5.0},
	{"label": "Chippies (large)", "cost": 4.50, "energy": 14.0, "thirst": -6.0, "sanity": 6.0},
	{"label": "Twisties", "cost": 3.00, "energy": 9.0, "thirst": -4.0, "sanity": 5.0},
	{"label": "Meat Pie", "cost": 4.50, "energy": 17.0, "thirst": -2.0, "sanity": 4.0},
	{"label": "Sausage Roll", "cost": 3.50, "energy": 13.0, "thirst": -2.0, "sanity": 3.0},
	{"label": "Toastie", "cost": 4.00, "energy": 13.0, "thirst": 0.0, "sanity": 4.0},
	{"label": "Energy Drink", "cost": 5.00, "energy": 26.0, "thirst": 8.0, "sanity": -3.0},
	{"label": "Fizzy Drink", "cost": 3.50, "energy": 10.0, "thirst": 16.0, "sanity": 4.0},
	{"label": "Bottled Water", "cost": 2.00, "energy": 0.0, "thirst": 30.0, "sanity": 1.0},
	{"label": "Flavoured Milk", "cost": 4.00, "energy": 14.0, "thirst": 18.0, "sanity": 6.0},
	{"label": "Bread (loaf)", "cost": 4.00, "energy": 10.0, "thirst": -1.0, "sanity": 1.0},
	{"label": "Milk (2L)", "cost": 5.00, "energy": 8.0, "thirst": 20.0, "sanity": 1.0},
	{"label": "Instant Noodles", "cost": 1.50, "energy": 11.0, "thirst": -5.0, "sanity": 2.0},
]


## Random selection from a menu, so the shop shows a different range each visit
## rather than the same handful every time.
static func pick_menu(menu: Array, count: int = 6) -> Array:
	var pool: Array = menu.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))
