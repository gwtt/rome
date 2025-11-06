extends BaseCapability
class_name PlayerMoveCapability

func should_activate() -> bool:
	return !component.is_block(Enums.CapabilityTags.Move)

func should_deactivate() -> bool:
	return component.is_block(Enums.CapabilityTags.Move)

func tick_active(delta) -> void:
	var move_vector = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
	var velocity: Vector2 = owner.velocity
	velocity.x += move_vector * component.horizontal_accelerate_speed * delta
	velocity.x = clamp(velocity.x, -component.max_speed, component.max_speed)
	if move_vector == 0:
		velocity.x = lerp(0.0, velocity.x, pow(2, -50 * delta))
	owner.velocity.x = velocity.x
	owner.move_and_slide()
