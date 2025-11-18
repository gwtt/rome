extends BaseComponent
class_name PlayerSkillComponent

@export var black_wave: PackedScene

func _on_skill_state_physics_processing(delta: float) -> void:
	owner.add_gravity(delta)

func heal() -> void:
	player_stat_component.player_data.soul -= 3
	player_stat_component.player_data.health += 5
	player_stat_component.state_chart.send_event("to_normal")	

var interval := 20
func generate_black_wave() -> void:
	var wave := SpawnerSystem.spawn(black_wave, owner.get_parent(), owner.global_position + Vector2(interval * player_stat_component.direction_x , 0))
	wave.direction = player_stat_component.direction_xddd
	player_stat_component.player_data.soul -= 3
	owner.velocity.x = -300 * player_stat_component.direction_x
	player_stat_component.state_chart.send_event("to_normal")
	
func _on_skill_state_entered() -> void:
	owner.velocity.x = 0
	if player_stat_component.skill_type == player_stat_component.SkillType.heal:
		state_machine.travel("回血")
	if player_stat_component.skill_type == player_stat_component.SkillType.black_wave:	
		state_machine.travel("黑波")
