extends KinematicBody


const GRAVITY = -24.8
var vel = Vector3()
const MAX_SPEED = 20
const JUMP_SPEED = 10
const ACCEL = 4.5

var dir = Vector3()

const DEACCEL = 16
const MAX_SLOPE_ANGLE = 40

var camera
var rotation_helper

var MOUSE_SENSITIVITY = 0.05

var valid_target = null
var target_bool = false
var score = 0


func _ready():
	camera = $Rotation_Helper/Camera
	rotation_helper = $Rotation_Helper
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	#print($Rotation_Helper/RayCast.get_collider())
	
	if $Rotation_Helper/RayCast.get_collider() != null and $Rotation_Helper/RayCast.get_collider().is_in_group("collectible"):
		valid_target = $Rotation_Helper/RayCast.get_collider().get_parent()
		valid_target.get_child(0).get_child(0).show()
		target_bool = true
	
	if ($Rotation_Helper/RayCast.get_collider() == null or !$Rotation_Helper/RayCast.get_collider().is_in_group("collectible")) and target_bool:
		valid_target.get_child(0).get_child(0).hide()
		valid_target = null
		target_bool = false
	
	if valid_target != null and Input.is_action_just_pressed("interact"):
		valid_target.hide()
		increase_score()
	
	if Input.is_action_just_pressed("win"):
		for i in 10:
			increase_score()

func process_input(_delta):
	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()
	
	var input_movement_vector = Vector2()
	
	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1
		
	input_movement_vector = input_movement_vector.normalized()
	
	# Basis vectors are already normalized.
	dir += -cam_xform.basis.z * input_movement_vector.y
	dir += cam_xform.basis.x * input_movement_vector.x
	# ----------------------------------
	
	# ----------------------------------
	# Jumping
	if is_on_floor():
		if Input.is_action_just_pressed("movement_jump"):
			vel.y = JUMP_SPEED
	# ----------------------------------
	
	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------


func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	vel.y += delta * GRAVITY
	
	var hvel = vel
	hvel.y = 0
	
	var target = dir
	target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		rotation_helper.rotation_degrees = camera_rot


func increase_score():
	score += 1
	if score < 7:
		$HUD_Layer/HUD/Score.text = "Score: " + str(score) + "/7"
	else:
		$HUD_Layer/HUD/Score.text = "YOU WIN!"
		get_parent().get_node("end_camera").set_current(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
