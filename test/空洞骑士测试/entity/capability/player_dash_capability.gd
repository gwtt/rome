extends BaseCapability
class_name PlayerDashCapability

func tick_active(delta: float) -> void:
	# 在地面时恢复 dash 能力
	if !component.can_dash and component.is_on_floor(): 
		component.can_dash = true
		return
	
	var velocity: Vector2 = owner.velocity
	
	# 检测 dash 输入并开始 dash
	if Input.is_action_just_pressed("dash") and component.can_dash:
		component.can_dash = false
		component.is_dashing = true
		# 设置 dash 结束回调（动画由 animation_capability 处理）
		component.dash_finished_callback = _on_dash_finished
		# 设置 dash 速度
		var dash_direction = sign(velocity.x)
		velocity.x = component.dash_speed * dash_direction
		velocity.y = 0
		owner.velocity = velocity
		# 阻塞移动和跳跃能力
		capability_component.block_capabilities(Enums.CapabilityTags.Move, self)
		capability_component.block_capabilities(Enums.CapabilityTags.Jump, self)

	# Dash 期间的速度衰减
	if component.is_dashing:
		velocity.x = lerp(0.0, velocity.x, pow(2, -6 * delta))
		owner.velocity = velocity
		owner.move_and_slide()

## Dash 动画播放结束回调（由 animation_capability 触发）
func _on_dash_finished() -> void:
	capability_component.unblock_capabilities(Enums.CapabilityTags.Move, self)
	capability_component.unblock_capabilities(Enums.CapabilityTags.Jump, self)
	component.is_dashing = false
	component.dash_finished_callback = Callable()
