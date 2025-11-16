extends BaseComponent
class_name BossJumpComponent

@export var jump_speed := 400

func _on_jump_state_physics_processing(_delta: float) -> void:
	owner.add_gravity(_delta)
	owner.turn_direction()
	if owner.velocity.y > 0:
		if boss_stat_component.is_punch_down:
			boss_stat_component.state_chart.send_event("to_punch_down")
			return
		state_machine.travel("下落")
	
	if owner.is_on_floor():
		owner.velocity = Vector2.ZERO
		boss_stat_component.state_chart.send_event("to_idle")
	
func _on_jump_state_entered() -> void:
	owner.velocity.y = -jump_speed
	if boss_stat_component.is_punch_down:
		owner.velocity.x = (boss_stat_component.player.global_position.x - owner.global_position.x) * 2
	else:
		owner.velocity.x = boss_stat_component.player.global_position.x - owner.global_position.x
	state_machine.travel("跳跃")

