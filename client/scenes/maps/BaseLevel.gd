extends Node

var other_player_template = preload("res://scenes/playerObjects/PlayerTemplate.tscn")
var main_player_template = preload("res://scenes/playerObjects/Player.tscn")

var spawn_location = Vector2.ZERO
var main_player = null
var map_bound = {
	"left": 0,
	"right": 1000,
	"bottom": 30,
	"top": -10000,
}

var greenGuy = preload("res://scenes/monsterObjects/000001/000001.tscn")
var monster_list = {
	'greenGuy': greenGuy,
}

func _ready():
	self.name = "currentScene"
	if Global.player.lastmap != get_scene_file_path():
		Global.update_lastmap(get_scene_file_path())
	spawn_location = Vector2(248,-407)
	$Player/Camera2D.limit_left = map_bound["left"]
	$Player/Camera2D.limit_right = map_bound["right"]
	$Player/Camera2D.limit_bottom = map_bound["bottom"]
	$Player/Camera2D.limit_top = map_bound["top"]

	if Global.last_portal:
		$Player.global_position = Global.last_portal
	print("Player: ", $Player.global_position, " Portal1: ", $MapObjects/Portal1.global_position)
	
func register_player(player):
		main_player = player
		main_player.connect("died", Callable(self, "on_player_died").bind(), CONNECT_DEFERRED)

func create_player():
	var player_instance = main_player_template.instance()
	add_sibling(main_player, player_instance)
	player_instance.global_position = spawn_location
	register_player(player_instance)

func on_player_died():
	print("Player Died")
	main_player.queue_free()
	print("Play Respawned")
	create_player()

func _on_noCol_body_entered(body):
	if body.is_in_group("player"):
		body.set_collision_layer_value(0, false)
		body.set_collision_mask_value(0, false)

func _on_noCol_body_exited(body):
	print("out of area")
	if body.is_in_group("player"):
		body.set_collision_layer_value(0, true)
		body.set_collision_mask_value(0, true)
