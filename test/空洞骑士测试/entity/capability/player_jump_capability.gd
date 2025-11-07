extends BaseCapability
class_name PlayerJumpCapability


func tick_active(delta: float) -> void:
	var velocity:Vector2 = owner.velocity
	
	if component.is_on_floor():
		component.can_jump = true
		component.can_double_jump = false
		component.is_double_jumping = false
	else:
		component.can_jump = false

	if Input.is_action_just_pressed("jump") and component.can_jump:
		DebugSystem.printDebug("跳跃", owner)
		component.can_jump = false
		velocity.y = -component.jump_speed

	if Input.is_action_just_pressed("jump") and component.can_double_jump:
		DebugSystem.printDebug("二段跳", owner)
		component.is_double_jumping = true
		component.can_double_jump = false
		velocity.y = -component.double_jump_speed 

	# 短跳/长跳逻辑：上升期如果松开跳跃键，增加额外重力
	if velocity.y < 0 and !Input.is_action_pressed("jump") and not component.is_double_jumping:
		# 长按跳：不追加额外上升期重力；松开则追加额外重力以实现短跳
		velocity.y += component.jump_higher * delta * component.gravity
		
	# 当开始下落时，允许二段跳
	if velocity.y > 0 and not component.can_jump and not component.is_double_jumping:
		component.can_double_jump = true

	# 应用重力
	velocity.y += component.gravity * delta
	owner.velocity = velocity
