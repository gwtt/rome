extends BaseComponent
class_name PlayerMoveComponent

func _on_move_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		player_stat_component.state_chart.send_event("to_jump")
		return
		
	var move_vector = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
	var velocity: Vector2 = owner.velocity
	
	# 处理水平移动
	velocity = _handle_horizontal_movement(delta, move_vector, velocity)
	owner.velocity = velocity
	
	if not owner.is_on_floor(): return
	if abs(velocity.x)<= 0.1:
		state_machine.travel("站立")	
	else:
		state_machine.travel("移动")
	
	if Input.is_action_just_pressed("heal") and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.heal
		player_stat_component.state_chart.send_event("to_skill")
		return
	if Input.is_action_just_pressed("black_wave") and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.black_wave
		player_stat_component.state_chart.send_event("to_skill")
		return	
## 处理水平移动
func _handle_horizontal_movement(delta: float, move_vector: float, velocity: Vector2) -> Vector2:
	if move_vector != 0:
		print(owner.velocity.x)
		player_stat_component.direction_x = sign(owner.velocity.x)
		owner.turn_direction()
		# 加速
		velocity.x += move_vector * player_stat_component.horizontal_accelerate_speed * delta
		velocity.x = clamp(velocity.x, -player_stat_component.max_speed, player_stat_component.max_speed)
	else:
		# 减速（摩擦力）
		velocity.x = lerp(0.0, velocity.x, pow(2, -50 * delta))
	return velocity
