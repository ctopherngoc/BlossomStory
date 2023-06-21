extends KinematicBody2D

#signal monster_died
#signal monster

###############################################
# old variables
var maxSpeed = 100
var velocity = Vector2.ZERO
var direction = Vector2.RIGHT
var gravity = 1600

# no jump, not used
var jumpSpeed = 500

var rng = RandomNumberGenerator.new()
var speedFactor = 0.5
var move_state
var experience = 25
var attackers = {}
onready var damage = 10
onready var take_damage = false
##########################################################
#currrent new variables
var title = "Green Guy"
var location = null
var current_hp = 25
var max_hp = 25
var state = "idle"
var stats = {
	"Attack" : 10,
	"Defense" : 5,
	"Magic Defense" : 5,
	"Accuracy" : 10,
	"Avoidability" : 5,
}
############################################################

func _ready():
	pass
	
func _process(delta):
	TouchDamage()
	
	# eventually incorperate take damage set aggro
	# skip rng movement algo
	
	# no jump mechanic yet
	if is_on_floor():
		var _my_random_number = rng.randi_range(1, 100)

		if move_state == 1:
			direction= Vector2.RIGHT
			velocity.x = (direction * maxSpeed *speedFactor).x

		elif move_state == 2:
			direction= Vector2.LEFT
			velocity.x = (direction * maxSpeed * speedFactor).x

		else:
			velocity.x = 0

	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)

func _on_Timer_timeout():
	move_state = floor(rand_range(0,3))# Replace with function body.


func NPCHit(dmg, player):
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
					var playerContainer = get_node("../../Players/%s" % attacker)
					
					# xp = rounded (dmg done / max hp) * experience 
					playerContainer.experience(int(round((attackers[attacker] / max_hp) * experience)))
				
		get_node("do_damage/CollisionShape2D").set_deferred("disabled", true)
		yield(get_tree().create_timer(0.2), "timeout")
		get_node("take_damage/CollisionShape2D").set_deferred("disabled", true)
		
	print("monster: " + self.name + " health: " + str(current_hp))
	
func TouchDamage():
	if $do_damage.get_overlapping_areas().size() > 0:
		for player in $do_damage.get_overlapping_areas():
			# call server to do damage to body
			
			Global.NPCAttack(player.get_parent(), stats)
	else:
		pass
