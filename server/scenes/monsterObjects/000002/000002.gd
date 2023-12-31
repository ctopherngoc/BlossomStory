extends KinematicBody2D

var id = '000002'
var title = "Blue Guy"
var location = null
var current_hp = 50
var max_hp = 50
var state = "idle"
var stats = {
	"level": 2,
	"boss": 0,
	"attack" : 15,
	"defense" : 10,
	"magicDefense" : 10,
	"accuracy" : 15,
	"avoidability" : 5,
	"experience": 30,
	"movementSpeed": 100,
	"jumpSpeed": 200,
}

var rng = RandomNumberGenerator.new()
var max_speed = 100
var velocity = Vector2.ZERO
var direction = Vector2.RIGHT
var gravity = 1600
var speed_factor = 0.5
var experience = 25
var move_state
var attackers = {}

func _ready():
	pass
	
func _process(delta):
	touch_damage()

	if is_on_floor():
		var _my_random_number = rng.randi_range(1, 100)

		if move_state == 1:
			direction= Vector2.RIGHT
			velocity.x = (direction * max_speed *speed_factor).x

		elif move_state == 2:
			direction= Vector2.LEFT
			velocity.x = (direction * max_speed * speed_factor).x

		else:
			velocity.x = 0

	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)

func _on_Timer_timeout():
	move_state = floor(rand_range(0,3))


func npc_hit(dmg, player):
	current_hp -= dmg
	if str(player) in attackers.keys():
		attackers[str(player)] += dmg
	else:
		attackers[str(player)] = dmg
	# if dead change state and make it unhittable
	if current_hp <= 0:
		state = "Dead"

		for attacker in attackers.keys():
			# if atacker logged in
			if attacker in ServerData.player_location.keys():

				# if attacker in map
				if get_node("../../Players/%s" % attacker):
					var player_container = get_node("../../Players/%s" % attacker)

					# xp = rounded (dmg done / max hp) * experience 
					player_container.experience(int(round((attackers[attacker] / max_hp) * experience)))

		get_node("do_damage/CollisionShape2D").set_deferred("disabled", true)

	print("monster: " + self.name + " health: " + str(current_hp))

func touch_damage():
	if $do_damage.get_overlapping_areas().size() > 0:
		for player in $do_damage.get_overlapping_areas():
			# call server to do damage to body
			Global.npc_attack(player.get_parent(), stats)

