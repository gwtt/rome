extends BaseComponent
class_name BossMoveComponent

@export var move_speed := 80
var distance := 80
func _on_move_state_physics_processing(_delta: float) -> void:
	#state_machine.travel("移动")
	owner.add_gravity(_delta)
	owner.turn_direction()
	owner.velocity.x = move_speed * boss_stat_component.direction_x
	owner.velocity.y = 0
	if abs(boss_stat_component.player.global_position.x - owner.global_position.x) < distance:
		boss_stat_component.state_chart.send_event("to_slash")
		
func _on_move_state_entered() -> void:
	state_machine.travel("移动")
