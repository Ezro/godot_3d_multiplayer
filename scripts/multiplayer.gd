extends Control

@onready var multiplayer_buttons = $Lobby/Buttons
@onready var host = $Lobby/Buttons/Host
@onready var join = $Lobby/Buttons/Join
@onready var Name = $Lobby/Name
@onready var NameLine = $Lobby/Name/LineEdit
@onready var id = $Id


@export var Address: String = "127.0.0.1"
@export var port: int = 8977
@export var PlayerScene : PackedScene

var peer: ENetMultiplayerPeer

func _ready():
    multiplayer.peer_disconnected.connect(peer_disconnected)
    multiplayer.connected_to_server.connect(connected_to_server)
    multiplayer.connection_failed.connect(connected_to_server)
    if "--server" in OS.get_cmdline_args():
        _on_host_button_down()

func peer_disconnected(id):
    print("(%s) %s Disconnected" % [multiplayer.get_unique_id(), id])
    GameManager.Players[id]["obj"].queue_free()
    GameManager.Players.erase(id)

func connected_to_server():
    print("(%s) %s connected to server!" % [multiplayer.get_unique_id(), NameLine.text])
    id.text = "Id: %s" % multiplayer.get_unique_id()
    id.name = str(multiplayer.get_unique_id())
    SendPlayerInformation.rpc_id(1, NameLine.text, multiplayer.get_unique_id())

func connection_failed():
    print("Couldn't connect to server")

func _on_host_button_down():
    setup_enet(true)
    multiplayer_buttons.hide()
    Name.hide()
    LoadGameScene()
    print("Waiting for players")
    id.text = "Id: %s" % multiplayer.get_unique_id()
    id.name = str(multiplayer.get_unique_id())

func _on_join_button_down():
    setup_enet(false)
    multiplayer_buttons.hide()
    Name.hide()
    LoadGameScene()

func setup_enet(is_server: bool):
    peer = ENetMultiplayerPeer.new()
    if is_server:
        var error = peer.create_server(port, 2)
        if error != OK:
            print("cannot host: " + error)
            return
    else:
        peer.create_client(Address, port)
    peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
    multiplayer.set_multiplayer_peer(peer)

func _on_start_button_down():
    LoadGameScene()

func LoadGameScene():
    var scene = load("res://scenes/demo_world.tscn").instantiate()
    get_tree().root.add_child(scene)

@rpc("any_peer", "call_remote", "reliable")
func SendPlayerInformation(player_name: String, id: int):
    if not multiplayer.is_server():
        return
    var player_equips: Array = _get_random_equips()
    var spawn = Vector3(3, 0, 52)
    LoadPlayer(player_name, id, player_equips, spawn)
    LoadPlayer.rpc_id(id, player_name, id, player_equips, spawn)
    LoadPlayer.rpc(player_name, id, player_equips, spawn)
    for p in GameManager.Players:
        var player = GameManager.Players[p]
        if player["id"] != id:
            print("Sending %s to %s" % [player["id"], id])
            var equips = player["obj"].get_node("Visuals").get_equips()
            # Send existing player to new player
            LoadPlayer.rpc_id(id, player["name"], player["id"], equips, player["obj"].global_position)

@rpc("authority", "call_remote", "reliable")
func LoadPlayer(player_name: String, id: int, equips: Array, loc: Vector3):
    if !GameManager.Players.has(id):
        var currentPlayer = preload("res://scenes/player.tscn").instantiate()
        currentPlayer.name = str(id)
        get_node("Players").add_child(currentPlayer)
        currentPlayer.global_position = loc
        print("(%s) Adding player %s %s %s" % [
            multiplayer.get_unique_id(),
            player_name,
            id,
            currentPlayer.global_position])
        var visuals = currentPlayer.get_node("Visuals")
        visuals.set_equips(equips)
        GameManager.Players[id] = {
            "name": player_name,
            "id": id,
            "obj": currentPlayer
        }
        #print("(%s) Spawned %s" % [multiplayer.get_unique_id(), GameManager.Players[id]])

func _get_random_equips():
    var current_player = PlayerScene.instantiate()
    var visuals = current_player.get_node("Visuals")
    var equips = visuals.randomize_equips()
    current_player.queue_free()
    return equips
