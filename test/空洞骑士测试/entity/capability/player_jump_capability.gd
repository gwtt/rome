extends BaseCapability
class_name PlayerJumpCapability

func tick_active(delta: float) -> void:
	var velocity: Vector2 = owner.velocity
	
	# 更新地面状态
	_update_ground_state()
	
	# 处理跳跃输入
	_handle_jump_input()
	
	# 重新获取 velocity（可能被跳跃输入修改）
	velocity = owner.velocity
	
	# 处理短跳/长跳逻辑
	_handle_variable_jump_height(delta)
	
	# 重新获取 velocity（可能被短跳逻辑修改）
	velocity = owner.velocity
	
	# 更新二段跳可用状态
	_update_double_jump_availability(velocity)
	
	# 应用重力
	velocity.y += component.gravity * delta
	owner.velocity = velocity

## 更新地面相关状态
func _update_ground_state() -> void:
	if component.is_on_floor():
		component.can_jump = true
		component.can_double_jump = false
		component.is_double_jumping = false
	else:
		component.can_jump = false

## 处理跳跃输入（一段跳和二段跳）
func _handle_jump_input() -> void:
	if !Input.is_action_just_pressed("jump"):
		return
	
	var velocity: Vector2 = owner.velocity
	
	# 一段跳
	if component.can_jump:
		DebugSystem.printDebug("跳跃", owner)
		component.can_jump = false
		velocity.y = -component.jump_speed
		owner.velocity = velocity
		return
	
	# 二段跳
	if component.can_double_jump:
		DebugSystem.printDebug("二段跳", owner)
		component.is_double_jumping = true
		component.can_double_jump = false
		velocity.y = -component.double_jump_speed
		owner.velocity = velocity

## 处理可变跳跃高度（短跳/长跳）
func _handle_variable_jump_height(delta: float) -> void:
	var velocity: Vector2 = owner.velocity
	# 上升期如果松开跳跃键，增加额外重力实现短跳
	if velocity.y < 0 and !Input.is_action_pressed("jump") and not component.is_double_jumping:
		velocity.y += component.jump_higher * delta * component.gravity
		owner.velocity = velocity

## 更新二段跳可用状态
func _update_double_jump_availability(velocity: Vector2) -> void:
	# 当开始下落且不在二段跳状态时，允许二段跳
	if velocity.y > 0 and not component.can_jump and not component.is_double_jumping:
		component.can_double_jump = true
