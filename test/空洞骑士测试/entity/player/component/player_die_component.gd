extends BaseComponent
class_name PlayerDieComponent


func _on_die_state_entered() -> void:
	state_machine.travel("死亡1")
