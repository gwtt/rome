extends BaseComponent
class_name BossDashComponent

var dash_velocity = 400
var dash_preparing := false
var dash_stopping := false
## 前方检测距离
@export var check_distance: float = 100.0

func _on_dash_state_physics_processing(delta: float) -> void:
	if dash_preparing:
		var current_pos := state_machine.get_current_play_position()
		var current_len := state_machine.get_current_length()
		if current_pos >= current_len:
			DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
			state_machine.travel("冲刺")
			owner.velocity.x = dash_velocity * boss_stat_component.direction_x
			owner.velocity.y = 0
			dash_preparing = false
			return
	
	if dash_stopping:
		state_machine.travel("冲刺停下")
		owner.velocity.x = lerp(0.0, owner.velocity.x, pow(2, -10 * delta))
		owner.add_gravity(delta)
		var current_pos := state_machine.get_current_play_position()
		var current_len := state_machine.get_current_length()
		if current_pos >= current_len:
			dash_stopping = false
			boss_stat_component.state_chart.send_event("to_idle")
	
	if not dash_preparing:
		if check_front_collision():
			dash_stopping = true
	
var ray_distance := 10
## 检测前方是否有层级1的物体
func check_front_collision() -> bool:
	var query = PhysicsRayQueryParameters2D.create(owner.global_position, owner.global_position + Vector2(ray_distance * boss_stat_component.direction_x, -5), 1)
	var collision = owner.get_world_2d().direct_space_state.intersect_ray(query)
	if collision:
		return true
	return false

func _on_dash_state_entered() -> void:
	owner.turn_direction()
	owner.velocity = Vector2.ZERO
	dash_preparing = true
	dash_stopping = false
	state_machine.start("冲刺准备")

