extends KinematicBody2D

# T: clock : {A: Attack animation}
var attack_dict = {}
var attacking = false

func _physics_process(_delta):
	if not attack_dict == {}:
		attack()

func move_player(new_position, animation):
		
	if animation["d"] == 1:
		get_node( "Head" ).set_flip_h( true )
		get_node( "Body" ).set_flip_h( true )
		get_node( "Ears" ).set_flip_h( true )
		get_node( "Arm" ).set_flip_h( true )
	else:
		get_node( "Head" ).set_flip_h( false )
		get_node( "Body" ).set_flip_h( false )
		get_node( "Ears" ).set_flip_h( false )
		get_node( "Arm" ).set_flip_h( false )
	
	if attacking == true:
		pass
	# if position same
	elif new_position == position:
		$AnimationPlayer.play("idle")
	# if player moved
	else:
		if animation["f"] == 1:
			$AnimationPlayer.play("walk")
		# is not on floor, y direciton move
		else:
			$AnimationPlayer.play("jump")
	set_position(new_position)
	
func _on_AnimationPlayer_animation_finished(animation_name):
	if animation_name == "stab":
		attacking = false
		
func attack():
	for attack in attack_dict.keys():
		print("there is an attack in dict")
		if attack <= Server.client_clock:
			print("before attacking animation")
			attacking = true
# warning-ignore:unused_variable
			var animation = $AnimationPlayer.play("stab")
			print("other player attack done")
			attack_dict.erase(attack)
			
