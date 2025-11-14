extends BaseComponent
class_name BossLiftComponent

var gravity := 1000
var lift_velocity_x := 80
var lift_velocity_y := 400
var lift_preparing := false

func _on_lift_state_physics_processing(_delta: float) -> void:
	if not lift_preparing:
		add_gravity(_delta)

func _on_lift_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	lift_preparing = true
	state_machine.travel("挥砍准备")
	await state_machine.state_finished
	DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
	lift_preparing = false
	owner.velocity.x = lift_velocity_x * boss_stat_component.direction_x
	owner.velocity.y = lift_velocity_y * -1
	state_machine.travel("挥砍")
	await state_machine.state_finished
	DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
	boss_stat_component.state_chart.send_event("to_idle")


func add_gravity(delta: float) -> void:
	owner.velocity.y += gravity * delta
