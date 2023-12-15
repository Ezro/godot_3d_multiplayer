extends Node3D

var hats: Array[String] = [
    "",
    "res://assets/pointy_hat.tres",
    "res://assets/black_box_hat.tres"
]

@export var Head: MeshInstance3D

var equipped: Array = [0]

func randomize_equips():
    var hat = randi_range(0, hats.size()-1)
    return [hat]

func set_equips(equips):
    equipped[0] = equips[0]
    var hat = hats[equipped[0]]
    if hat != "":
        Head.mesh = load(hat)

func get_equips():
    return equipped
