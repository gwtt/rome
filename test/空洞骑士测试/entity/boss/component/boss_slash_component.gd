extends BaseComponent
class_name BossSlashComponent

var slash_velocity = 300
var slash_preparing := false

func _on_slash_state_physics_processing(_delta: float) -> void:
	if slash_preparing:
		var current_pos = state_machine.get_current_play_position()
		var current_len = state_machine.get_current_length()
		if current_pos >= current_len:
			state_machine.travel("挥砍")
			DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
			owner.velocity.x = slash_velocity * boss_stat_component.direction_x
			owner.velocity.y = 0
			slash_preparing = false
		return
		
	if not slash_preparing:
		owner.add_gravity(_delta)
		var current_pos = state_machine.get_current_play_position()
		var current_len = state_machine.get_current_length()
		if current_pos >= current_len:
			DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
			boss_stat_component.state_chart.send_event("to_lift")
	
func _on_slash_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	slash_preparing = true
	state_machine.start("挥砍准备")

