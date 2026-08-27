extends HBoxContainer

## The hotbar. Alongside the item icons it now carries the unread-message
## badge: a red circle with a number on whichever slot is holding the Phone,
## exactly like an app icon on a real home screen.
##
## The badge is created once per slot (invisible until it has a count) and
## Notifier keeps every registered badge in sync, so this never disagrees with
## the badge on the phone's own Messages icon.

var slots: Array
## slot index -> badge Control
var _badges: Dictionary = {}


func _ready():
	get_slots()
	Inventory.inventory_changed.connect(_update_hotbar)
	Inventory.slot_selected.connect(_highlight_slot)
	GameBackend.messages_changed.connect(_refresh_badges)
	_update_hotbar()
	# Inventory is the FIRST autoload in project.godot, so Notifier does not
	# exist yet at this point in the boot order. Deferring by one frame is the
	# whole fix — by then every autoload is up.
	call_deferred("_setup_badges")


func get_slots():
	slots = get_children()
	for slot: TextureButton in slots:
		slot.pressed.connect(Inventory.select_slot.bind(slot.get_index()))


## One badge per slot, made once and left invisible until it has a count.
##
## Deliberately attach_badge() and NOT attach_message_badge(): the latter
## registers the badge with Notifier, and Notifier's global refresh sets every
## registered badge to the unread total — which is exactly why a red circle
## was appearing on all four slots instead of just the phone. These badges are
## ours to drive, from _refresh_badges() below.
func _setup_badges() -> void:
	if not has_node("/root/Notifier"):
		return
	for slot: TextureButton in slots:
		if _badges.has(slot.get_index()):
			continue
		_badges[slot.get_index()] = Notifier.attach_badge(slot, 20.0, Vector2(4, -4))
	_refresh_badges()


func _update_hotbar():
	for slot: TextureButton in slots:
		var item = Inventory.hotbar[slot.get_index()]
		slot.texture_normal = item.icon if item else null
	_refresh_badges()


## Only the slot actually holding the Phone shows a count. Move the phone to
## another slot and the badge moves with it.
func _refresh_badges() -> void:
	if not has_node("/root/Notifier"):
		return
	var unread: int = GameBackend.unread_count
	for slot: TextureButton in slots:
		var idx: int = slot.get_index()
		var badge: Control = _badges.get(idx, null)
		if badge == null or not is_instance_valid(badge):
			continue
		var item = Inventory.hotbar[idx]
		var holds_phone: bool = item != null and item.item_name == "Phone"
		Notifier.set_badge_count(badge, unread if holds_phone else 0)


func _highlight_slot(slot_index: int):
	for i in range(slots.size()):
		slots[i].modulate = Color(1, 1, 1)
	slots[slot_index].modulate = Color(1.5, 1.5, 1.5)
