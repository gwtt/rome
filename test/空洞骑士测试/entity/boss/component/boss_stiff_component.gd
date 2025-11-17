extends BaseComponent
class_name BossStiffComponent

var stiff_velocity = 400

func _on_stiff_state_physics_processing(delta: float) -> void:
	owner.add_gravity(delta)
	owner.velocity.x = lerp(0.0, owner.velocity.x, pow(2, -10 * delta))
	var current_pos := state_machine.get_current_play_position()
	var current_len := state_machine.get_current_length()
	if current_pos >= current_len:
		boss_stat_component.is_punch_down = false
		boss_stat_component.state_chart.send_event("to_normal")
		
func _on_stiff_state_entered() -> void:
	boss_stat_component.is_stiff = true
	state_machine.travel("僵直2")
	owner.velocity.x = stiff_velocity * Vector2(owner.global_position.x - boss_stat_component.player.global_position.x, 0).normalized().x

func _on_stiff_state_exited() -> void:
	boss_stat_component.is_stiff = false
