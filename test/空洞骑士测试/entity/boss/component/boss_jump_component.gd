extends BaseComponent
class_name BossJumpComponent

@export var move_speed := 80
@export var jump_speed := 400
var distance := 80

func _on_jump_state_physics_processing(_delta: float) -> void:
	owner.add_gravity(_delta)
	owner.turn_direction()
	if owner.velocity.y > 0:
		state_machine.travel("下落")
	
	if owner.is_on_floor():
		owner.velocity = Vector2.ZERO
		boss_stat_component.state_chart.send_event("to_idle")
	
func _on_jump_state_entered() -> void:
	owner.velocity.x = boss_stat_component.player.global_position.x - owner.global_position.x
	owner.velocity.y = -jump_speed
	state_machine.travel("跳跃")

