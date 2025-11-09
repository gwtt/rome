extends BaseCapability
class_name PlayerMovementAnimationCapability


func tick_active(_delta: float) -> void:
	var next_anim := _get_next_animation()
	
	component.play_anim(next_anim)

## 根据当前状态决定下一个动画
func _get_next_animation() -> String:
	var velocity = owner.velocity
	var on_floor = component.is_on_floor()
	
	if not on_floor:
		# 空中状态：根据是否二段跳和速度方向选择动画
		if component.is_double_jumping:
			return "二段跳" if velocity.y < 0.0 else "下落"
		else:
			return "跳跃" if velocity.y < 0.0 else "下落"
	elif abs(velocity.x) > 0.0:
		# 地面移动
		return "移动"
	else:
		# 地面站立
		return "站立"
