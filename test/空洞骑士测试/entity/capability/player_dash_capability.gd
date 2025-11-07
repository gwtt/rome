extends BaseCapability
class_name PlayerDashCapability

func tick_active(delta) -> void:
	if !component.can_dash and component.is_on_floor(): 
		component.can_dash = true
		return
	var velocity: Vector2 = owner.velocity
	if Input.is_action_just_pressed("dash") and component.can_dash:
		component.can_dash = false
		component.is_dashing = true
		component.play_anim("冲刺", _on_dash_finished)
		velocity.x = component.dash_speed * sign(velocity.x)
		velocity.y = 0
		capability_component.block_capabilities(Enums.CapabilityTags.Move, self)
		capability_component.block_capabilities(Enums.CapabilityTags.Jump, self)

	if component.is_dashing:
		velocity.x = lerp(0.0, velocity.x, pow(2, -6 * delta))
		owner.velocity = velocity
		owner.move_and_slide()
	
## 冲刺动画播放结束回调
func _on_dash_finished() -> void:
	capability_component.unblock_capabilities(Enums.CapabilityTags.Move, self)
	capability_component.unblock_capabilities(Enums.CapabilityTags.Jump, self)
	component.is_dashing = false
