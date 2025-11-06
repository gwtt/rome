extends BaseCapability
class_name PlayerDashCapability

func on_active() -> void:
	component.block_capabilities(Enums.CapabilityTags.Dash, self)

func tick_active(delta) -> void:
	var velocity: Vector2 = owner.velocity
	var can_dash := component.is_block(Enums.CapabilityTags.Dash)
	if Input.is_action_just_pressed("dash") and can_dash:
		component.play_anim("冲刺", _on_dash_finished)
		velocity.x = component.dash_speed * sign(velocity.x)
		velocity.y = 0
		component.block_capabilities(Enums.CapabilityTags.Move, self)
		component.block_capabilities(Enums.CapabilityTags.Jump, self)
		component.unblock_capabilities(Enums.CapabilityTags.Dash, self)
		can_dash = false
	if can_dash: return
	velocity.x = lerp(0.0, velocity.x, pow(2, -6 * delta))
	owner.velocity = velocity
	owner.move_and_slide()
	
## 冲刺动画播放结束回调
func _on_dash_finished() -> void:
	component.unblock_capabilities(Enums.CapabilityTags.Move, self)
	component.unblock_capabilities(Enums.CapabilityTags.Jump, self)
	component.block_capabilities(Enums.CapabilityTags.Dash, self)
