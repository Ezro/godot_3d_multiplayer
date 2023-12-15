extends MultiplayerSynchronizer

@export var input_motion: Vector2
@export var jumping: bool = false
@export var camera_3D: Node3D


func _ready():
    if get_parent().name == str(multiplayer.get_unique_id()):
        camera_3D.make_current()
    else:
        set_process(false)
        set_process_input(false)

func _process(_delta):
    input_motion = Input.get_vector("left", "right", "forward", "back")
    if Input.is_action_just_pressed("jump"):
        jump.rpc_id(1)

func _input(event):
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        if event is InputEventMouseMotion:
            # TODO: rotate_camera
            pass

@rpc("call_local")
func jump():
    jumping = true
