extends CharacterBody3D

@onready var animated_sprite_2d = $CanvasLayer/GunBase/AnimatedSprite2D
@onready var animation_player = $CanvasLayer/GunBase/AnimationPlayer
@onready var ray_cast_3d = $RayCast3D
@onready var shoot_sound = $ShootSound
@onready var out_of_ammo_sound = $OutOfAmmoSound
@onready var reload_sound = $ReloadSound
@onready var gun_base = $CanvasLayer/GunBase
@onready var camera = $Head/Camera3D
@onready var head = $Head
@onready var ammo_display = $CanvasLayer/GunBase/AmmoDisplay

const BOB_FREQ = 2.0
const BOB_AMP= 0.08

const WALK_SPEED = 10.0
const SPRINT_SPEED = 13.0
const MOUSE_SENS = 0.3

const JUMP_VELOCITY = 4.5

var gravity = 9.8
var t_bob = 0.0

var current_ammo = 7

var speed

var can_shoot = true
var dead = false

func _ready():
	Input.mouse_mode= Input.MOUSE_MODE_CAPTURED
	animated_sprite_2d.animation_finished.connect(shoot_anim_done)
	$"CanvasLayer/Death screen/Panel/Button".button_up.connect(restart)
	
func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		head.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		camera.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40),deg_to_rad(60))
	
func _process(_delta):
	ammo_display.text = str(current_ammo) + "/7"
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	if dead:
		return
	if Input.is_action_just_pressed("shoot"):
		shoot()
	if Input.is_action_just_pressed("reload"):
		if current_ammo!=7:
			reload()
		else:
			return

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		animation_player.speed_scale = 2
		speed = SPRINT_SPEED
	else:
		animation_player.speed_scale = 1
		speed = WALK_SPEED
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			animation_player.play("gunsway")
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		velocity.x = lerp(velocity.x, direction.x*speed,delta*2.0)
		velocity.z = lerp(velocity.z, direction.z*speed,delta*2.0)

	#Head bob
	t_bob+= delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	move_and_slide()
	
func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time* BOB_FREQ) * BOB_AMP
	pos.x = cos(time* BOB_FREQ/2) * BOB_AMP
	return pos


func restart():
	get_tree().reload_current_scene()
	
func shoot():
	if current_ammo==0:
		out_of_ammo_sound.play()
		return
	if !can_shoot:
		return
	can_shoot = false
	animated_sprite_2d.play("shoot")
	current_ammo-=1
	shoot_sound.play()
	if ray_cast_3d.is_colliding() and ray_cast_3d.get_collider().has_method("kill"):
		ray_cast_3d.get_collider().kill()
		
func shoot_anim_done():
	can_shoot=true

func reload():
	can_shoot=false
	reload_sound.play()
	await get_tree().create_timer(1.0).timeout
	current_ammo = 7
	can_shoot = true

func kill():
	dead=true
	$"CanvasLayer/Death screen".show()
	Input.mouse_mode= Input.MOUSE_MODE_VISIBLE
