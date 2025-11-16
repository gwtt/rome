extends BaseComponent
class_name BossBackJumpComponent

@export var jump_speed := 400
@export var left_point := Vector2.ZERO
@export var right_point := Vector2.ZERO

func _on_back_jump_state_physics_processing(delta: float) -> void:
	owner.add_gravity(delta)
	if owner.velocity.y > 0:
		if sign(owner.velocity.x) == sign(boss_stat_component.direction_x):
			state_machine.travel("下落")
		else:
			state_machine.travel("后跳下落")
	if owner.is_on_floor():
		owner.velocity = Vector2.ZERO
		boss_stat_component.state_chart.send_event("to_idle")

func _on_back_jump_state_entered() -> void:
	owner.velocity.y = -jump_speed
	var player_position = boss_stat_component.player.global_position
	var boss_positon = owner.global_position
	owner.velocity.x = left_point.x - boss_positon.x if player_position.x > (left_point.x + right_point.x) / 2.0 else right_point.x - boss_positon.x
	if sign(owner.velocity.x) == sign(boss_stat_component.direction_x):
		state_machine.travel("跳跃")
	else:
		state_machine.travel("后跳")


