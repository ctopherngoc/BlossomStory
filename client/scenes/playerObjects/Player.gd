extends KinematicBody2D

# dynamic player variables
#onready var player = Global.player
onready var jump_speed
onready var health
onready var max_horizontal_speed
onready var velocity = Vector2.ZERO
onready var damage

# static player varaibles
onready var horizontal_acceleration = 3
onready var knockback_modifier = 0.2
onready var gravity = 800

# player states
export var can_climb = false
export var is_climbing = false
export var no_collision_zone = false
onready var direction = "RIGHT"
onready var attacking = false
onready var player_state

onready var animation = {
	"f": 1,
	"d": 1
}

func _ready():
	# timer.set_wait_time(1.5)
	#player = Global.register_player()
	$Label.text = Global.player.displayname
	max_horizontal_speed = (Global.player.stats.movementSpeed)
# warning-ignore:return_value_discarded
	Signals.connect("dialog_closed", self, "movable_switch")
	
	jump_speed = (Global.player.stats.jumpSpeed)
# warning-ignore:return_value_discarded
	$take_damage.connect("area_entered", self, "on_hazard_area_entered")
	get_node( "Head" ).set_flip_h( true )
	get_node( "Body" ).set_flip_h( true )
	get_node( "Ears" ).set_flip_h( true )
	get_node( "Arm" ).set_flip_h( true )
	get_node( "Weapon" ).scale.x = -1

func _physics_process(delta):
	if Global.movable:
		movement_loop(delta)
	#define_player_state()
	# update_health_display()

func define_player_state():
	player_state = {"T": Server.client_clock, "P": get_global_position(), "M": Global.current_map, "A": animation}
	Server.send_player_state(player_state)

func movement_loop(delta):
	change_direction()
	var move_vector = get_movement_vector()
	
	# change get velocity
	get_velocity(move_vector, delta)
	# warning-ignore:return_value_discarded
	move_and_slide(velocity, Vector2.UP)
	
	# player state if jumping
	if is_on_floor():
		animation["f"] = 1
	else:
		animation["f"] = 0
	
	if is_on_floor() or !is_climbing:
		velocity = move_and_slide(velocity, Vector2.UP)
	if is_climbing:
		velocity.x = 0

	update_animation()

func get_movement_vector():
	var moveVector = Vector2.ZERO
	
	# calculating x vector, allow x-axis jump off ropes or idle on floor
	if (!attacking && is_on_floor()) or (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")) and Input.get_action_strength("jump"):
		moveVector.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * .8
	else:
		moveVector.x = 0	
	# calculating y vector, allow jump off ropes
	if is_climbing:
		if (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")) and Input.get_action_strength("jump"):
			moveVector.y = -1
		else:
			moveVector.y = 0
	else:
		if Input.get_action_strength("jump") && !attacking:
			moveVector.y = -1
		else:
			moveVector.y = 0
	return moveVector

func get_velocity(move_vector, delta):
	velocity.x += move_vector.x * horizontal_acceleration
	# slow down movement
	if(move_vector.x == 0):
		# allows forward jumping
		if(is_on_floor()):
			velocity.x = lerp(0, velocity.x, pow(2, -50 * delta))

	velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	
	if can_climb:
		if is_climbing:
			velocity.y = 0
			if Input.is_action_pressed("ui_up"):
				velocity.y = -100
			elif Input.is_action_pressed("ui_down"):
				velocity.y = 100
				#if is_on_floor():
					#is_climbing = false
			# jump off rope
			elif Input.is_action_pressed("jump") && (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
				#is_climbing = false
				velocity.y = move_vector.y * jump_speed * .8
				velocity.x = move_vector.x * 200
		# can climb but not climbing
		else:
			#if moving
			if (move_vector.y < 0 && is_on_floor()):
					velocity.y = move_vector.y * jump_speed
			# press up on ladder initiates climbing
			elif (!is_on_floor() && Input.is_action_pressed("ui_up")) or (is_on_floor() && Input.is_action_pressed("ui_down")):
					#is_climbing = true
					self.set_collision_layer_bit(0, false)
					self.set_collision_mask_bit(0, false)
					velocity.y = 0
					velocity.x = 0
			# over lapping ladder pressing nothing allows gravity
			else:
				velocity.y += gravity * delta
	# not climbable state
	else:
		# normal movement
		if (move_vector.y < 0 && is_on_floor()):
			velocity.y = move_vector.y * jump_speed
		else:
			velocity.y += gravity * delta
	
	#if !can_climb:
		#is_climbing = false

# attack > jump > walking > takeDamage > standing
func update_animation():
	var move_vector = get_movement_vector()
	
	if(attacking):
		pass

	elif(Input.is_action_pressed("attack") && !is_climbing && Global.movable):
		$AnimationPlayer.playback_speed = 0.75
		attacking = true
		$AnimationPlayer.play("stab")

	else:
		$AnimationPlayer.playback_speed = 1.0
		if(!is_on_floor()):
			$AnimationPlayer.play("jump")

		elif(move_vector.x != 0):
			$AnimationPlayer.play("walk")
	#	elif(tookDamage):
	#		$Head.play("hit")
	#		$Arm.play("hit")
	#		$Body.play("hit")
	#		$Ears.play("hit")
	#		$RightH.play("idle")
	#		$LeftH.play("hit")
	#		$RightHHit.play('hit')

		else:
			$AnimationPlayer.play("idle")

func movable_switch():
	Global.movable = true

func change_direction():
	if Input.is_action_pressed("move_right") && !attacking && !Input.is_action_pressed("move_left"):
		direction = "RIGHT"
		if velocity.x < 0 && is_on_floor():
			velocity.x = 0
		get_node( "Head" ).set_flip_h( true )
		get_node( "Body" ).set_flip_h( true )
		get_node( "Ears" ).set_flip_h( true )
		get_node( "Arm" ).set_flip_h( true )
		get_node( "Weapon" ).scale.x = -1
		get_node("do_damage").scale.x = 1
		animation["d"] = 1
	elif Input.is_action_pressed("move_left") && !attacking && !Input.is_action_pressed("move_right"):
		direction = "LEFT"
		if velocity.x > 0 && is_on_floor():
			velocity.x  = 0
		get_node( "Head" ).set_flip_h( false )
		get_node( "Body" ).set_flip_h( false )
		get_node( "Ears" ).set_flip_h( false )
		get_node( "Arm" ).set_flip_h( false )
		get_node( "Weapon" ).scale.x = 1
		get_node("do_damage").scale.x = -1
		animation["d"] = 0

#########################################################################################
# floor collision while in air
func _on_Area2D_area_entered(_area):
	no_collision_zone = true
	self.set_collision_layer_bit(0, false)
	self.set_collision_mask_bit(0, false)
	print("no col")

func _on_Area2D_area_exited(_area):
	no_collision_zone = false
	self.set_collision_layer_bit(0, true)
	self.set_collision_mask_bit(0, true)
	print("col")
##########################################################################################
# attacking functions
func set_damage(damage_value):
	damage = damage_value
	print("player set damage = %s" % damage)

func _on_AnimationPlayer_animation_finished(animation_name):
	if animation_name == "stab":
		attacking = false
		
func _unhandled_input(event):
	if event.is_action_pressed("attack"):
		if Global.movable:
			Server.send_attack(1)
		else:
			print("cannot attack")

func overlappingBodies():
	print("area ovlapping: " + str($do_damage.get_overlapping_areas().size()))
	for body in $do_damage.get_overlapping_areas():
		print('player overlapping with: ', body)

######################################################################################
# functions to work on
#################################
#knock back function
# warning-ignore:unused_argument
func on_hazard_area_entered(area2d):
	pass
	#recieve_knockback(area2d.global_position)

# warning-ignore:unused_argument
func recieve_knockback(damage_source_pos: Vector2):
	pass
#	var knockback_direction = damage_source_pos.direction_to(self.global_position)
#	var knockback = knockback_direction * knockback_modifier *40	
#	self.global_position += knockback

# not used anymore?
# take damage function
"""
func take_damage():
	if !took_damage:
		if $take_damage.get_overlapping_areas().size() > 0:
			print("touch damage. HP = ", player.stats.mapValue.fields.health.doubleValue)
			took_damage = true
			if (player.stats.mapValue.fields.health.doubleValue <= 0):
				# respawn hp
				took_damage = false
				player.stats.mapValue.fields.health.doubleValue = 25
				print("died update")
				Global.update_player(player)
				emit_signal("died")
			else:
				$take_damage.set_monitoring(false) 
				timer.start()


func _on_Timer_timeout():
	timer.stop()
	took_damage = false
	$take_damage.set_monitoring(true) 

# insert iFrame
func on_hazard_area_exit(_area2d):
	if $take_damage.get_overlapping_areas().size() == 0:
		print("no overlapping bodies")
		
func update_health_display():
	$HP.text = str(player["stats"]["health"])
	# emit global signal send hp value -> global signal emits signal to ui to update hp value
"""
