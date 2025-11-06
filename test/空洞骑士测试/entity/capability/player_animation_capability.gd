extends BaseCapability
class_name PlayerAnimationCapability

func on_active() -> void:
	tick_group = Enums.ETickGroup.AfterMovement
	
func tick_active(_delta: float) -> void:
	component.turn_direction()
	# 如果 Dash 标签不被阻塞
	if not component.is_block(Enums.CapabilityTags.Dash):
		return

	var velocity = owner.velocity
	var on_floor = owner.is_on_floor()
	var next_anim := "站立"
	if not on_floor:
		next_anim = "跳跃" if velocity.y < 0.0 else "下落"
	elif abs(velocity.x) > 1.0:
		next_anim = "移动"
	component.play_anim(next_anim)

