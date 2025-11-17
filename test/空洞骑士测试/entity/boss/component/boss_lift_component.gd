extends BaseComponent
class_name BossLiftComponent

var lift_velocity_x := 80
var lift_velocity_y := 400
var lift_preparing := false

func _on_lift_state_physics_processing(_delta: float) -> void:
	if lift_preparing:
		var current_pos = state_machine.get_current_play_position()
		var current_len = state_machine.get_current_length()
		if current_pos >= current_len:
			state_machine.travel("上挑")
			DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
			lift_preparing = false
			owner.velocity.x = lift_velocity_x * boss_stat_component.direction_x
			owner.velocity.y = lift_velocity_y * -1
		return
		
	if not lift_preparing:
		owner.add_gravity(_delta)
		var current_pos = state_machine.get_current_play_position()
		var current_len = state_machine.get_current_length()	
		if current_pos >= current_len:
			DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
			boss_stat_component.state_chart.send_event("to_idle")
			
func _on_lift_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	state_machine.travel("上挑准备")
	lift_preparing = true

