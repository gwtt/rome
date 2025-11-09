extends BaseComponent
class_name PlayerDashComponent

@export var player_black_dash_component: PlayerBlackDashComponent

func _on_dash_state_entered() -> void:
	var velocity: Vector2 = owner.velocity	
	stat_component.can_dash = false
	state_machine.state_finished.connect(on_dash_finished)
	if stat_component.has_black_dash:
		stat_component.has_black_dash = false
		player_black_dash_component.spawn_blackdash()
		state_machine.travel("黑冲")
	else:
		state_machine.travel("冲刺")
	var dash_direction = sign(velocity.x)
	velocity.x = stat_component.dash_speed * dash_direction
	velocity.y = 0
	owner.velocity = velocity
	
func _on_dash_state_physics_processing(delta: float) -> void:
	var velocity: Vector2 = owner.velocity
	velocity.x = lerp(0.0, velocity.x, pow(2, -6 * delta))
	owner.velocity = velocity
	
	var current_pos := state_machine.get_current_play_position()
	var current_len := state_machine.get_current_length()

	if current_pos >= current_len:
		stat_component.state_chart.send_event("to_movement")
		state_machine.state_finished.disconnect(on_dash_finished)

		
func on_dash_finished(anim_name: StringName) -> void:
	if anim_name == "冲刺":
		stat_component.state_chart.send_event("to_movement")
		state_machine.state_finished.disconnect(on_dash_finished)
	DebugSystem.printDebug(anim_name + "结束", self, "red")

func _on_move_ment_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("dash") and stat_component.can_dash:
		stat_component.state_chart.send_event("to_dash")
