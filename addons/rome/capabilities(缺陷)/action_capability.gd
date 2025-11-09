extends BaseCapability
class_name ActionCapability

## ActionCapability: 只有当它位于队列最前端时才会检查ShouldActivate，并且它会一直停留在那里直到失活（Deactivating）。
func on_become_front_of_queue() -> void:
	pass
	
func on_removed_from_queue() -> void:
	pass
