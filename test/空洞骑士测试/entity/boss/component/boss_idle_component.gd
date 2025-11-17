extends BaseComponent
class_name BossIdleComponent

var distance := 80

func _on_idle_state_physics_processing(_delta: float) -> void:
	owner.turn_direction()
	owner.add_gravity(_delta)
	var current_pos := state_machine.get_current_play_position()
	var current_len := state_machine.get_current_length()
	if current_pos >= current_len:
		if randf() < 0.5:
			if abs(boss_stat_component.player.global_position.x - owner.global_position.x) < distance:
				boss_stat_component.state_chart.send_event("to_slash")
			else:
				if randf() < 0.5:
					boss_stat_component.state_chart.send_event("to_move")
				else:
					boss_stat_component.state_chart.send_event("to_jump")
		else:
			if randf() > 0.5:
				boss_stat_component.state_chart.send_event("to_back_jump")
			else:
				boss_stat_component.is_punch_down = true
				boss_stat_component.state_chart.send_event("to_jump")
			
func _on_idle_state_entered() -> void:
	owner.velocity.x = 0
	state_machine.travel("站立")



