extends BaseCapability
class_name PlayerJumpCapability

func should_activate() -> bool:
	return !component.is_block(Enums.CapabilityTags.Jump)

func should_deactivate() -> bool:
	return component.is_block(Enums.CapabilityTags.Jump)
	
func tick_active(delta) -> void:
	var velocity:Vector2 = owner.velocity
	if Input.is_action_just_pressed("jump"):
		if not owner.is_on_floor(): return
		velocity.y = -component.jump_speed
	if velocity.y < 0 and !Input.is_action_pressed("jump"):
		# 长按跳：不追加额外上升期重力；松开则追加额外重力以实现短跳
		velocity.y += component.jump_higher * delta * component.gravity
	velocity.y += component.gravity * delta
	owner.velocity.y = velocity.y
