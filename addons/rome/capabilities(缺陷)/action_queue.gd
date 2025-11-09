extends Node

func empty() -> void:
	pass
	
func idle(duration: float) -> void:
	pass
	
func event(function_owner: Node, callback: Callable) -> void:
	pass
	
func duration(duration: float, function_owner: Node, callback: Callable) -> void:
	pass

func capability(capability_owner: Node, sub_class: ActionCapability) -> void:
	pass

func set_looping(b_looping: bool) -> void:
	pass
