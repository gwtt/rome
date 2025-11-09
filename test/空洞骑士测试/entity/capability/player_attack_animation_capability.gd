extends BaseCapability
class_name PlayerAttackAnimationCapability

var attack_index := 0

func should_activate() -> bool:
	if !Input.is_action_just_pressed("attack"):
		return false
	return true

func on_active() -> void:
	capability_component.block_capabilities(Enums.CapabilityTags.MoveAnimation, self)
	attack_index = attack_index % 2 + 1
	component.play_anim("横劈" + str(attack_index), _on_attack_finished)

func _on_attack_finished() -> void:
	capability_component.unblock_capabilities(Enums.CapabilityTags.MoveAnimation, self)
