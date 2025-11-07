extends BaseCapability
class_name PlayerAnimationCapability

func on_active() -> void:
	tick_group = Enums.ETickGroup.AfterMovement
	
func tick_active(_delta: float) -> void:
	component.turn_direction()

	# 冲刺动画优先级最高
	if component.is_dashing:
		return

	var velocity = owner.velocity
	var on_floor = component.is_on_floor()
	var next_anim := "站立"
	
	if not on_floor:
		# 空中状态：根据是否二段跳和速度方向选择动画
		if component.is_double_jumping:
			next_anim = "二段跳" if velocity.y < 0.0 else "下落"
		else:
			next_anim = "跳跃" if velocity.y < 0.0 else "下落"
	elif abs(velocity.x) > 1.0:
		# 地面移动
		next_anim = "移动"
	# else: 保持默认的 "站立"
	
	component.play_anim(next_anim)
