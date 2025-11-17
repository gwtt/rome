extends BaseComponent
class_name PlayerHealComponent


func _on_heal_state_physics_processing(_delta: float) -> void:
	owner.add_gravity(_delta)
	state_machine.travel("回血")

func heal() -> void:
	player_stat_component.player_data.soul -= 3
	player_stat_component.player_data.health += 5
	player_stat_component.state_chart.send_event("to_normal")
