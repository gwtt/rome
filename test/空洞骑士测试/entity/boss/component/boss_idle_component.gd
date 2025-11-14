extends BaseComponent
class_name BossIdleComponent

var gravity := 1000
var was_facing_right := false
var is_facing_right := false

func _on_idle_state_physics_processing(_delta: float) -> void:
	turn_direction()
	add_gravity(_delta)
	
## 旋转方向
func turn_direction() -> void:
	if boss_stat_component.player:
		DebugSystem.printHighlight("玩家位置: " + str(boss_stat_component.player.global_position.x), self)
		DebugSystem.printHighlight("Boss位置: " + str(owner.global_position.x), self)
		## 如果玩家位置在Boss左边
		var direction = 1 if boss_stat_component.player.global_position.x < owner.global_position.x else -1
		if direction == 1:
			was_facing_right = false
		else:
			was_facing_right = true
		if 	is_facing_right != was_facing_right:
			is_facing_right = was_facing_right
			owner.scale.x = abs(owner.scale.x) * -1
		#owner.global_scale.x = direction	
		#if owner.scale.x != direction:
			#owner.scale.x *= direction
		#DebugSystem.printHighlight(str(owner.scale.x), self)
		if direction == 1:
			DebugSystem.printHighlight("Boss朝向: 右", self)
		else:
			DebugSystem.printHighlight("Boss朝向: 左", self)
		DebugSystem.printHighlight(str(owner.scale), self)
		boss_stat_component.direction_x = -direction
		
func add_gravity(delta: float) -> void:
	owner.velocity.y += gravity * delta
	
func _on_idle_state_entered() -> void:
	owner.velocity.x = 0
	#turn_direction()
	state_machine.travel("站立")
	await state_machine.state_finished
	DebugSystem.printHighlight("当前节点:" + state_machine.get_current_node(), self)
	boss_stat_component.state_chart.send_event("to_slash")


#func _on_idle_state_exited() -> void:
	#turn_direction()
