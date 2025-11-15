extends BaseComponent
class_name BossPunchDownComponent

@export var bone_spur: PackedScene

enum punch_down_enum {
	PREPARE,
	DO,
	FINISH,
}

var state = punch_down_enum.PREPARE
var punch_down_velocity := 100
var offset_x = 50

func _on_punch_down_state_physics_processing(_delta: float) -> void:
	if state == punch_down_enum.DO:
		owner.velocity.y += punch_down_velocity
		if owner.is_on_floor():
			spawn_bone_spurs()
			state_machine.travel("下戳结束")
			state = punch_down_enum.FINISH
	
	if state == punch_down_enum.FINISH:
		var current_pos := state_machine.get_current_play_position()
		var current_len := state_machine.get_current_length()
		if current_pos >= current_len:
			boss_stat_component.is_punch_down = false
			boss_stat_component.state_chart.send_event("to_idle")
			
func _on_punch_down_state_entered() -> void:
	state = punch_down_enum.PREPARE
	owner.velocity = Vector2.ZERO
	state_machine.start("下戳准备")
	await state_machine.state_finished
	DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
	state = punch_down_enum.DO

func spawn_bone_spurs() -> void:
	var temp_offset = Vector2(offset_x, 0)
	var space_state = owner.get_world_2d().direct_space_state
	var check_height = 100.0  # 向上检测的高度
	
	for i in range(10):
		# 左侧位置向上100高度的检测点
		var target_position_left = owner.global_position - temp_offset + Vector2(0, -check_height)
		var query_left = PhysicsPointQueryParameters2D.new()
		query_left.position = target_position_left
		query_left.collision_mask = 1
		query_left.collide_with_areas = true
		query_left.collide_with_bodies = true
		var collision_left = space_state.intersect_point(query_left)
		if collision_left.is_empty():
			SpawnerSystem.spawn_at_direction(bone_spur, owner, -1, -temp_offset)
		
		# 右侧位置向上100高度的检测点
		var target_position_right = owner.global_position + temp_offset + Vector2(0, -check_height)
		var query_right = PhysicsPointQueryParameters2D.new()
		query_right.position = target_position_right
		query_right.collision_mask = 1
		query_right.collide_with_areas = true
		query_right.collide_with_bodies = true
		var collision_right = space_state.intersect_point(query_right)
		if collision_right.is_empty():
			SpawnerSystem.spawn_at_direction(bone_spur, owner, 1, temp_offset)
		
		temp_offset.x += offset_x
		await get_tree().create_timer(0.2).timeout
