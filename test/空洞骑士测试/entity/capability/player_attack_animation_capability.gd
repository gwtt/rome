extends BaseCapability
class_name PlayerAttackAnimationCapability

func should_activate() -> bool:
	if !Input.is_action_just_pressed("attack"):
		return false
	return true

func on_active() -> void:
	component.play_anim("横劈1")


