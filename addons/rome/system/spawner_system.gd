extends Node

## 通用生成实例化管理器
## 用于在场景中生成和管理各种实例

## 从场景文件生成实例
func spawn(scene: PackedScene, parent: Node = null, global_position: Vector2 = Vector2.ZERO, local_position: Vector2 = Vector2.ZERO) -> Node:
	if not scene:
		DebugSystem.printError("无法加载场景: ", scene.get_name())
		return null
	
	var instance = scene.instantiate()
	if not instance:
		DebugSystem.printError("无法加载场景: ", scene.get_name())
		return null
	
	# 确定父节点
	var target_parent: Node = parent
	if not target_parent:
		# 如果没有指定父节点，添加到当前场景树
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			target_parent = tree.current_scene
		if not target_parent:
			push_error("无法找到有效的父节点")
			instance.queue_free()
			return null
	
	# 添加到场景树
	target_parent.add_child(instance)
	
	# 设置位置
	if instance is Node2D:
		if global_position != Vector2.ZERO:
			instance.global_position = global_position
		else:
			instance.position = local_position
	
	return instance

## 在指定节点的左右方向生成实例
func spawn_at_direction(scene: PackedScene, source_node: Node2D, direction: int = 1, offset: Vector2 = Vector2.ZERO, parent: Node = null) -> Node:
	if not source_node:
		push_error("源节点不能为空")
		return null
	
	# 计算生成位置
	var spawn_position = source_node.global_position + offset
	# 如果offset.x为0，根据direction设置默认偏移
	if offset.x == 0:
		spawn_position.x += direction * 50  # 默认偏移50像素
	else:
		# 如果offset.x不为0，直接使用offset，但确保方向正确
		# offset.x的正负值已经表示了方向，所以直接加上即可
		pass
	
	# 确定父节点
	var target_parent: Node = parent if parent else source_node.get_parent()
	
	return spawn(scene, target_parent, spawn_position)

## 在节点的左右两侧同时生成实例
func spawn_both_sides(scene: PackedScene, source_node: Node2D, left_offset: Vector2 = Vector2(-50, 0), right_offset: Vector2 = Vector2(50, 0), parent: Node = null) -> Array:
	var instances := []
	
	# 生成左侧实例
	var left_instance = spawn_at_direction(scene, source_node, -1, left_offset, parent)
	if left_instance:
		instances.append(left_instance)
	
	# 生成右侧实例
	var right_instance = spawn_at_direction(scene, source_node, 1, right_offset, parent)
	if right_instance:
		instances.append(right_instance)
	
	return instances
