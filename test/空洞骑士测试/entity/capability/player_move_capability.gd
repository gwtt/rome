extends BaseCapability
class_name PlayerMoveCapability

func tick_active(delta: float) -> void:
	var move_vector = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
	var velocity: Vector2 = owner.velocity
	
	# 处理水平移动
	velocity = _handle_horizontal_movement(delta, move_vector, velocity)
	owner.velocity = velocity
	component.turn_direction()
	owner.move_and_slide()

## 处理水平移动
func _handle_horizontal_movement(delta: float, move_vector: float, velocity: Vector2) -> Vector2:
	if move_vector != 0:
		# 加速
		velocity.x += move_vector * component.horizontal_accelerate_speed * delta
		velocity.x = clamp(velocity.x, -component.max_speed, component.max_speed)
	else:
		# 减速（摩擦力）
		velocity.x = lerp(0.0, velocity.x, pow(2, -50 * delta))
	return velocity
