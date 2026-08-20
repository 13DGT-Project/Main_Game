extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

var gravity = 9.81

#Head Bobbing variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.2
var t_bob = 0.0

#fov variable
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var exhausted := false
const SPRINT_DRAIN := 20.0
const ENERGY_REGEN := 10.0
# NOTE: energy itself now lives on GameBackend (autoload), not here, so it
# survives scene changes (e.g. going to school/work and coming back). Sprint
# still reads/writes it via GameBackend.change_energy() below.





@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Inventory.item_drop.connect(drop_from_player)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90),deg_to_rad(90))
	elif event.is_action_pressed("use_item"):
		_use_selected_item()


func _use_selected_item() -> void:
	var item: ItemData = Inventory.hotbar[Inventory.selected_slot]
	if item == null:
		return
	match item.item_name:
		"Phone":
			PhoneApp.toggle()
		"Water Bottle":
			if not GameBackend.use_water_bottle():
				print("Your water bottle is empty — find a tap or fountain to refill it.")


func _physics_process(delta: float) -> void:
	if %SeeCast.is_colliding():
		var target = %SeeCast.get_collider()
		if target == null:
			return
		
		if Input.is_action_just_pressed("interact"):
			print("It's a " + target.name)
			
			if target.is_in_group("interactable"):
				target.interact()
		
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	#Handle Sprint
	#if Input.is_action_pressed("sprint"):
	#	speed = SPRINT_SPEED
	#else:
	#	speed = WALK_SPEED
	if GameBackend.energy <= 0:
		exhausted = true

	if exhausted and GameBackend.energy >= 25:
		exhausted = false

	if Input.is_action_pressed("sprint") and !exhausted:
		speed = SPRINT_SPEED
		GameBackend.change_energy(-SPRINT_DRAIN * delta)
	else:
		speed = WALK_SPEED
		GameBackend.change_energy(ENERGY_REGEN * delta)
	
	
	
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed,delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed,delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed,delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed,delta * 3.0)


	#Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	
func drop_from_player(item):
	var forward = -transform.basis.z.normalized()
	var drop_pos = global_position - forward * 2.0
	item.global_position = drop_pos
