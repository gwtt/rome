extends BaseCapability
class_name PlayerAnimationCapability

var current_anim: String = ""

func on_active() -> void:
	tick_group = Enums.ETickGroup.AfterMovement
	
func tick_active(_delta: float) -> void:
	component.turn_direction()

	var next_anim := _get_next_animation()
	
	# 只在动画需要改变时播放，避免重复播放
	if next_anim != current_anim:
		component.play_anim(next_anim)
		current_anim = next_anim

## 根据当前状态决定下一个动画
func _get_next_animation() -> String:
	# 冲刺动画优先级最高
	if component.is_dashing:
		return "冲刺"
	
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
