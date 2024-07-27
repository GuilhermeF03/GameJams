extends CharacterBody2D

@export_category("Constants")
@export_range(100, 500, 50) var MOV_SPEED = 300
@export_range(200, 1000, 100) var DODGE_SPEED = 600
@export_range(0.5, 5) var DODGE_COOLDOWN : float = 0.5
@export_range(10, 500) var MAX_MOUSE_DRIFT = 250
@export_range(1, 10) var MOUSE_DRIFT_FACTOR : float = 3.25

@export_category("Nodes")
@onready var inventory : Inventory = $Inventory
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite
@onready var dodge_timer = $Timers/DodgeTimer
@onready var weapon = $Weapon
@onready var weapon_handler : WeaponHandler = $Weapon/WeaponHandler
@onready var camera = $PhantomCamera2D

@export_category("Animation")
var dodging = false
var inventory_on = false
var back_view = false


func _ready():
	dodge_timer.wait_time = DODGE_COOLDOWN


func _physics_process(_delta):
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	handle_movement(input)
	handle_animation(input)
	handle_weapon()
	handle_camera()
	
	get_tree().paused = inventory_on


func handle_movement(input):
	self.velocity = input.normalized() * (DODGE_SPEED if dodging else MOV_SPEED)
	move_and_slide()


func handle_weapon():
	weapon.look_at(get_global_mouse_position())
	weapon_handler.scale.y = -5 if get_local_mouse_position().x < 0 else 5


func handle_camera():
	if inventory_on: return
	
	var axis = (
		get_global_mouse_position() - LevelManager.player.global_position
	) + Vector2.UP * 200 # Add offset to camera
	
	var axis_normalized = (axis * 10).normalized()
	var mouse_drift = axis_normalized * MAX_MOUSE_DRIFT
	
	var lower_bound = axis_normalized if axis_normalized < mouse_drift else mouse_drift
	var upper_bound = axis_normalized if axis_normalized > mouse_drift else mouse_drift 
	
	camera.follow_offset = clamp(
		axis / MOUSE_DRIFT_FACTOR,
		lower_bound,
		upper_bound
	)
	
	sprite.scale.x = -5 if (axis / MOUSE_DRIFT_FACTOR).x < 0 else 5


func dodge():
	var input = velocity.normalized()
	back_view = input.y < 0
	
	animation_player.play("roll_" + ("up" if back_view else "down"));
	dodging = true
	dodge_timer.start()
	

# region Inputs


func _input(event : InputEvent):
	handle_inventory_toggle_input(event)
	
	# Skip input handling if on inventory
	if inventory.handling_input: return
	
	handle_tool_selection(event)
	handle_dodge_input(event)
	handle_attack_input(event)


func handle_inventory_toggle_input(event : InputEvent):
	# Toggle inventory
	if event.is_action_pressed("inventory"):
		inventory_on = !inventory_on
		inventory.handling_input = !inventory.handling_input
		
		if inventory_on: inventory.open()
		else: inventory.close()


func handle_dodge_input(event : InputEvent):
	if (
		event.is_action_pressed("dodge") 
		and dodge_timer.is_stopped() 
		and velocity != Vector2.ZERO
	):
		dodge()


func handle_attack_input(event : InputEvent):
	if (
		event.is_action_pressed("attack") 
		and weapon_handler.can_attack
		and !dodging
	):
		weapon_handler.attack()


func handle_tool_selection(event : InputEvent): # TODO - change this to work with mouse wheel
	if (
		event.is_pressed() 
		and !event.is_echo() 
		and event.as_text().is_valid_int()
	):
		var tool = event.as_text().to_int() - 1
		inventory.tools.select_tool(tool)


# endregion

# region Animation

func handle_animation(input):
	# Dodging - wait
	if dodging: return
	
	# Set Idle
	if input == Vector2.ZERO:
		animation_player.play("idle_" + ("up" if back_view else "down"))
		return
	# Freeze movement with inventory on
	if inventory_on: return
	
	back_view = input.y < 0
	
	animation_player.play("walk_" + ("up" if back_view else "down"));


func _on_animation_finished(anim_name):
	if anim_name == "roll_up" or anim_name == "roll_down":
		dodging = false

# endregion