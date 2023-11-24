extends Node

@onready var ip = "127.0.0.1"

const interpolation_offset = 100
@onready var mosnter_spawn
@onready var current_map = ""
@onready var bgm = $bgm
var other_player = preload("res://scenes/playerObjects/PlayerTemplate.tscn")
var last_world_state = 0
var world_state_buffer = []

var character_list = []
var player = null
var last_portal = null

# loads player info
func _ready():
	pass
	
# scene gets player info
func register_player():
	return player

func update_lastmap(map):
	player.lastmap = map
	
func change_background():
	RenderingServer.set_default_clear_color(Color(0.4,0.4,0.4,1.0))
		
func update_world_state(world_state):
	if world_state["T"] > last_world_state:
		last_world_state = world_state["T"]
		world_state_buffer.append(world_state)

func _physics_process(_delta):
	var render_time = OS.get_system_time_msecs() - interpolation_offset
	if world_state_buffer.size() > 1 && Server.server_status:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].T:
			world_state_buffer.remove(0)
		# has future state
		if world_state_buffer.size() > 2:
			var interpolation_factor = float(render_time - world_state_buffer[1]["T"]) / float(world_state_buffer[2]["T"] - world_state_buffer[0]["T"])
			for player_state in world_state_buffer[2]["P"].keys():
				if player_state == get_tree().get_unique_id():
					continue
				if not world_state_buffer[1]["P"].has(player_state):
					continue
				if world_state_buffer[1]["P"][player_state]["M"] == Global.current_map:
					if get_node("/root/currentScene/OtherPlayers").has_node(str(player_state)):
						#print(world_state_buffer[2]["P"][player_state]["P"])
						var new_position = lerp(world_state_buffer[1]["P"][player_state]["P"], world_state_buffer[2]["P"][player_state]["P"], interpolation_factor)
						var animation = world_state_buffer[2]["P"][player_state]["A"]
						get_node("/root/currentScene/OtherPlayers/" + str(player_state)).move_player(new_position, animation)
					
					# check if character map == client map
					else:
						print("Spawning Player")
						spawn_new_player(player_state, world_state_buffer[2]["P"][player_state])
				else:
					despawn_player(player_state)
					
			# map keys can be empty
			if world_state_buffer[2]["E"][current_map].size() > 0:
				#spawn monsters function
				for monster in world_state_buffer[2]["E"][current_map].keys():
					if not world_state_buffer[1]["E"][current_map].has(monster):
						continue
					# monster not dead on client
					if get_node("/root/currentScene/Monsters").has_node(str(monster)):
						var monster_node = get_node("/root/currentScene/Monsters/" + str(monster))
						# monster dead on server
						if world_state_buffer[2]["E"][current_map][monster]["EnemyHealth"] <= 0:
							if monster_node.despawn != 0:
								monster_node.on_death()
						# monster alive: update monster stats and position
						else:
							var new_position = lerp(world_state_buffer[1]["E"][current_map][monster]["EnemyLocation"], world_state_buffer[2]["E"][current_map][monster]["EnemyLocation"], interpolation_factor)
							monster_node.move(new_position)
							monster_node.health(world_state_buffer[1]["E"][current_map][monster]["EnemyHealth"])
					else:
						# if actually alive respawned monster
						if world_state_buffer[2]["E"][current_map][monster]['time_out'] != 0 && world_state_buffer[2]["E"][current_map][monster]['EnemyState'] != "Dead":
							spawn_monster(monster, world_state_buffer[2]["E"][current_map][monster])

			# we have no future world_state
		elif render_time > world_state_buffer[1].T:
			var extrapolation_factor = float(render_time - world_state_buffer[0]["T"]) / float(world_state_buffer[1]["T"] - world_state_buffer[0]["T"]) - 1.00
			for player_state in world_state_buffer[1]["P"].keys():
				if player_state == get_tree().get_unique_id():
					continue
				if not world_state_buffer[0]["P"].has(player_state):
					continue
				if world_state_buffer[0]["P"][player_state]["M"] == Global.current_map:
					# move char if other character scene is in client, this should be later be determined by the server
					if get_node("/root/currentScene/OtherPlayers").has_node(str(player_state)):
						var position_delta = (world_state_buffer[1]["P"][player_state]["P"] - world_state_buffer[0]["P"][player_state]["P"])
						var new_position = world_state_buffer[1]["P"][player_state]["P"] + (position_delta * extrapolation_factor)
						var animation = world_state_buffer[1]["P"][player_state]["A"]
						get_node("/root/currentScene/OtherPlayers/" + str(player_state)).move_player(new_position, animation)

func spawn_new_player(player_id, player_state):
	if player_id == get_tree().get_unique_id():
		pass
	else:
		var new_player = other_player.instantiate()
		new_player.position = get_node("/root/currentScene").spawn_location
		new_player.name = str(player_id)
		get_node("/root/currentScene/OtherPlayers").add_child(new_player)
		get_node("/root/currentScene/OtherPlayers/%s/Label" % player_id).text = player_state["U"]

func despawn_player(player_id):
	if get_node("/root/currentScene/OtherPlayers").has_node(str(player_id)):
		print("despawning %s" % player_id)
		get_node("/root/currentScene/OtherPlayers/%s" % str(player_id)).queue_free()
		
func spawn_monster(monster_id, monster_dict):
	var monster = get_node("/root/currentScene").monster_list[monster_dict['id']].instantiate()
	monster.position = monster_dict["EnemyLocation"]
	monster.max_hp = monster_dict["EnemyMaxHealth"]
	monster.current_hp = monster_dict["EnemyHealth"]
	monster.state = monster_dict["EnemyState"]
	monster.name = str(monster_id)
	get_node("/root/currentScene/Monsters").add_child(monster, true)
