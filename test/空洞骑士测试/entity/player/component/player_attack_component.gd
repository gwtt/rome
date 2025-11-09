extends BaseComponent
class_name PlayerAttackComponent

var attack_index := 1
var attack_time := 0.0


func _on_attack_state_physics_processing(_delta: float) -> void:
	attack_time += _delta
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveDown") and not owner.is_on_floor() and attack_time > 0.1:
		state_machine.travel("下劈")
		attack_time= 0
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveUp") and attack_time > 0.1:
		state_machine.travel("上劈")
		attack_time= 0	
	if Input.is_action_just_pressed("attack") and attack_time > 0.1:
		state_machine.travel("横劈" + str(attack_index))
		attack_index = attack_index % 2 + 1
		attack_time= 0

