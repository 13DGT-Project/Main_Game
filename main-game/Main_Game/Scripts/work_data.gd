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

# --- Restocking minigame item pool (matches texture filenames you'll import) ---
var _restock_items: Array = [
	{"name": "Milk", "texture": "res://Backend/Resource/Textures/item_milk.png"},
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png"},
	{"name": "Canned Beans", "texture": "res://Backend/Resource/Textures/item_can.png"},
	{"name": "Apples", "texture": "res://Backend/Resource/Textures/item_apple.png"},
	{"name": "Chips", "texture": "res://Backend/Resource/Textures/item_chips.png"},
]

# --- Checkout minigame item pool, each with a price so a "total" can be shown ---
var _checkout_items: Array = [
	{"name": "Milk", "texture": "res://Backend/Resource/Textures/item_milk.png", "price": 4.50},
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png", "price": 3.20},
	{"name": "Canned Beans", "texture": "res://Backend/Resource/Textures/item_can.png", "price": 2.10},
	{"name": "Apples", "texture": "res://Backend/Resource/Textures/item_apple.png", "price": 5.80},
	{"name": "Chips", "texture": "res://Backend/Resource/Textures/item_chips.png", "price": 4.00},
]


# --- Bakery minigame item pool: things you're baking, used with the timing QTE ---
var _bakery_items: Array = [
	{"name": "Bread", "texture": "res://Backend/Resource/Textures/item_bread.png"},
	{"name": "Croissants", "texture": "res://Backend/Resource/Textures/item_croissant.png"},
	{"name": "Cake", "texture": "res://Backend/Resource/Textures/item_cake.png"},
]

# --- Deli (meat & fish counter) item pool, same shape as restock items ---
var _deli_items: Array = [
	{"name": "Meat", "texture": "res://Backend/Resource/Textures/item_meat.png"},
	{"name": "Fish", "texture": "res://Backend/Resource/Textures/item_fish.png"},
	{"name": "Sausages", "texture": "res://Backend/Resource/Textures/item_sausage.png"},
]


func get_bakery_round(count: int = 4) -> Array:
	var round_items: Array = []
	var kinds := ["knead", "bake"]
	for i in count:
		var item: Dictionary = _bakery_items[randi() % _bakery_items.size()].duplicate()
		item["kind"] = kinds[randi() % kinds.size()]
		round_items.append(item)
	return round_items


func get_deli_round(count: int = 5) -> Array:
	var round_items: Array = []
	var kinds := ["chop", "slice"]
	for i in count:
		var item: Dictionary = _deli_items[randi() % _deli_items.size()].duplicate()
		item["kind"] = kinds[randi() % kinds.size()]
		round_items.append(item)
	return round_items


func get_customer_questions(count: int = 3) -> Array:
	var pool: Array = _customer_questions.duplicate(true)
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


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
		round_items.append(_checkout_items[randi() % _checkout_items.size()])
	return round_items
