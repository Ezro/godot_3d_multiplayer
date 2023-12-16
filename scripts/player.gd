extends CharacterBody3D

@onready var visuals = $Visuals
@onready var camera_3d = $Camera3D
@onready var player_input = $PlayerInput

const SPEED = 3.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

enum ANIMATIONS { IDLE, JUMP, WALK }
@export var current_animation:int = int(ANIMATIONS.WALK)
@export var sync_pos: Vector3
@export var equips: Array

func _ready():
    $ServerSync.set_multiplayer_authority(1)
    player_input.set_multiplayer_authority(str(name).to_int())

func _physics_process(delta):
    if not multiplayer.is_server():
        global_position = global_position.lerp(sync_pos, .5)
        visuals.global_position = global_position
        if equips != null and equips.size() > 0 and equips != visuals.get_equips():
            visuals.set_equips(equips)
        return
    apply_input(delta)
    sync_pos = global_position
    if equips != visuals.get_equips():
        equips = visuals.get_equips()

func apply_input(delta: float = 0.0):
    if not is_on_floor():
        velocity.y -= gravity * delta
    if player_input.jumping and is_on_floor():
        velocity.y = JUMP_VELOCITY
        player_input.jumping = false
    var direction = (transform.basis * Vector3(player_input.input_motion.x, 0, player_input.input_motion.y)).normalized()
    velocity.x = direction.x * SPEED if direction else move_toward(velocity.x, 0, SPEED)
    velocity.z = direction.z * SPEED if direction else move_toward(velocity.z, 0, SPEED)
    move_and_slide()
