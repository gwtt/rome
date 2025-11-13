extends BaseComponent
class_name PlayerAttackComponent

var attack_index := 1
var attack_time := 0.0
var attack_interval := 0.1

func _on_attack_state_physics_processing(_delta: float) -> void:
	attack_time += _delta
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveDown") and not owner.is_on_floor() and attack_time > attack_interval:
		DebugSystem.printDebug("下劈", owner)
		state_machine.start("下劈")
		attack_time= 0
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveUp") and attack_time > attack_interval:
		DebugSystem.printDebug("上劈", owner)
		state_machine.start("上劈")
		attack_time= 0	
	if Input.is_action_just_pressed("attack") and attack_time > attack_interval:
		DebugSystem.printDebug("横劈" + str(attack_index), owner)
		state_machine.start("横劈" + str(attack_index))
		attack_index = attack_index % 2 + 1
		attack_time= 0
	
## https://github.com/godotengine/godot/issues/110128 bug问题
func _on_attack_area_area_entered(_area: Area2D) -> void:
	var current_anim = state_machine.get_current_node()
	if current_anim == "下劈":
		player_stat_component.can_double_jump = true
		player_stat_component.can_dash = true
		player_stat_component.is_double_jumping = false
		var velocity: Vector2 = owner.velocity
		velocity.x = 0
		velocity.y = -200
		owner.velocity = velocity
		state_machine.travel("下劈")
		return
	if player_stat_component.flip_h:
		owner.global_position.x -= 5
	else:
		owner.global_position.x += 5

