## 用于内置 Godot 节点和类型的辅助函数，以协助完成常见任务。
## 这里的大部分内容应该是 Godot 内置的，但并不是 :')
## 并且无法注入到基础类型（如 Node 等）中 :(

class_name Tools
extends GDScript



#region Constants

## 基本方向和中间方向，每个都分配一个数字，表示相关的旋转角度（以度为单位），东 = 0，每次递增 45 度
enum CompassDirection {
	# 设计：从东开始以匹配默认旋转角度 0
	# 待定：这应该在 `Tools.gd` 中还是在 `Global.gd` 中？ :')
	none		=  -1,
	east		=   0,
	southEast	=  45,
	south		=  90,
	southWest	= 135,
	west		= 180,
	northWest	= 225,
	north		= 270,
	northEast	= 315
	}

const compassDirectionVectors: Dictionary[CompassDirection, Vector2i] = {
	CompassDirection.none:		Vector2i.ZERO,
	CompassDirection.east:		Vector2i.RIGHT,
	CompassDirection.southEast:	Vector2i(+1, +1),
	CompassDirection.south:		Vector2i.DOWN,
	CompassDirection.southWest:	Vector2i(-1, +1),
	CompassDirection.west:		Vector2i.LEFT,
	CompassDirection.northWest:	Vector2i(-1, -1),
	CompassDirection.north:		Vector2i.UP,
	CompassDirection.northEast:	Vector2i(+1, -1)
	}

const compassDirectionOpposites: Dictionary[CompassDirection, CompassDirection] = {
	CompassDirection.none:		CompassDirection.none,
	CompassDirection.east:		CompassDirection.west,
	CompassDirection.southEast:	CompassDirection.northWest,
	CompassDirection.south:		CompassDirection.north,
	CompassDirection.southWest:	CompassDirection.northEast,
	CompassDirection.west:		CompassDirection.east,
	CompassDirection.northWest:	CompassDirection.southEast,
	CompassDirection.north:		CompassDirection.south,
	CompassDirection.northEast:	CompassDirection.southWest,
	}

## 表示 8 个罗盘方向的单位向量列表。
class CompassVectors:
	# 待定：是否用 `compassDirectionVectors[CompassDirection]` 替换？
	const none		:= Vector2i.ZERO
	const east		:= Vector2i.RIGHT
	const southEast	:= Vector2i(+1, +1)
	const south		:= Vector2i.DOWN
	const southWest	:= Vector2i(-1, +1)
	const west		:= Vector2i.LEFT
	const northWest	:= Vector2i(-1, -1)
	const north		:= Vector2i.UP
	const northEast	:= Vector2i(+1, -1)

## 用于 [method Array.pick_random]，带有可选的缩放因子。
const plusMinusOneOrZero:		Array[int]	 = [-1, 0, +1] # 待定：命名 :')

## 用于 [method Array.pick_random]，带有可选的缩放因子。
const plusMinusOneOrZeroFloat:	Array[float] = [-1.0, 0.0, +1.0] # 待定：命名 :')

## 用于 [method Array.pick_random]，带有可选的缩放因子。
const plusMinusOne:				Array[int]	 = [-1, +1] # 待定：命名 :')

## 用于 [method Array.pick_random]，带有可选的缩放因子。
const plusMinusOneFloat:		Array[float] = [-1.0, +1.0] # 待定：命名 :')

## 从 -1.0 到 +1.0 的浮点数序列，步长为 0.1
## 提示：使用 [method Array.pick_random] 从此列表中为颜色等选择随机变化。
const sequenceNegative1toPositive1stepPoint1: Array[float] = [-1.0, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, +0.1, +0.2, +0.3, +0.4, +0.5, +0.6, +0.7, +0.8, +0.9, +1.0] # 待定：更好的名字 :')

#endregion


#region Subclasses

## [method CanvasItem.draw_line] 的参数集
class Line: # 未使用：直到 Godot 可以支持自定义类 @export :')
	var start:	Vector2
	var end:	Vector2
	var color:	Color = Color.WHITE
	var width:	float = -1.0 ## 负值意味着线条将保持为"2点图元"，即无论缩放如何，始终是 1 宽度的线条。

#endregion


#region Scene Management
# See SceneManager.gd
#endregion


#region Script Tools

## 仅在连接尚不存在时连接或重新连接 [Signal] 到 [Callable]，以消除关于现有连接的烦人 Godot 错误（可能是为了引用计数）。
static func connectSignal(sourceSignal: Signal, targetCallable: Callable, flags: int = 0) -> int:
	if not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # 不知道返回值是什么。
	else:
		return 0


## 仅在连接实际存在时断开 [Signal] 与 [Callable] 的连接，以消除关于缺失连接的烦人 Godot 错误（可能是为了引用计数）。
static func disconnectSignal(sourceSignal: Signal, targetCallable: Callable) -> void:
	if  sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)


## 根据 [param reconnect] 标志，安全地连接/重新连接或断开 [Signal] 与 [Callable] 的连接。
## 提示：这避免了必须输入 `if someFlag: connectSignal(…) else: disconnectSignal(…)`
static func toggleSignal(sourceSignal: Signal, targetCallable: Callable, reconnect: bool, flags: int = 0) -> int:
	# 待定：`reconnect` 应该是可空的 Variant 吗？
	if reconnect and not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # 不知道返回值是什么。
	elif not reconnect and sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)
	# else:
	return 0


## [method Object.call] 或 [method Object.callv] 的安全包装器，如果函数/方法名缺失则不会崩溃。
## 返回调用的结果。
## 提示：对于传递可自定义函数很有用，例如在 `Animations.gd` 上动态选择不同的动画
static func callCustom(object: Variant, functionName: StringName, ...arguments: Array) -> Variant:
	if object.has_method(functionName):
		return object.callv(functionName, arguments)
	else:
		DebugSystem.printWarning(str("callCustom(): ", object, " has no such function: " + functionName), "Tools.gd")
		return null


## 从 [Script] 类型返回带有 `class_name` 的 [StringName]。
## 注意：需要此方法，因为我们无法直接编写 `SomeTypeName.get_global_name()` :(
func getStringNameFromClass(type: Script) -> StringName:
	return type.get_global_name()


## 检查脚本是否具有指定名称的函数/方法。
## 注意：仅检查名称，不检查参数或返回类型。
## 警告：使用与要查找的方法完全相同的大小写！
static func findMethodInScript(script: Script, methodName: StringName) -> bool: # 待定：应该是 [StringName] 吗？
	# 待办：检查多个方法的变体或选项。
	# 待办：检查参数和返回类型。
	var methodDictionary: Array[Dictionary] = script.get_script_method_list()
	for method in methodDictionary:
		# 调试：Debug.printDebug(str("findMethodInScript() script: ", script, " searching: ", method))
		if method["name"] == methodName: return true
	return false

#endregion


#region Node Management

## 调用 [param parent].[method Node.add_child] 并设置 [param child].[member Node.owner]。
## 这对于保存/加载时持久化到 [PackedScene] 是必需的。
## 注意：还设置 `force_readable_name` 参数，如果频繁使用可能会降低性能。
static func addChildAndSetOwner(child: Node, parent: Node) -> void: # 设计：待定：`parent` 应该是第 1 个参数还是第 2 个？所有全局函数都在第 1 个参数（父 [Node]）上操作，但此方法的名称以"child"为第一个词，所以 `child` 应该是第 1 个参数，对吗？ :')
	parent.add_child(child, DebugSystem.shouldForceReadableName) # 性能：仅在调试时使用 force_readable_name
	child.owner = parent


## 在另一个节点的位置添加并返回子节点，并可选择复制 [member placementNode] 的旋转和缩放。
## 还将子节点的所有者设置为新父节点。
## 示例：在从模板进行程序化地图生成时，使用 [Marker2D] 作为门等对象的占位符。
## 注意：还设置 `force_readable_name` 参数，如果频繁使用可能会降低性能。
static func addChildAtNode(child: Node2D, placementNode: Node2D, parent: Node, copyRotation: bool = true, copyScale: bool = true) -> Node2D:
	child.position = placementNode.position
	if copyRotation: child.rotation	= placementNode.rotation
	if copyScale:	 child.scale	= placementNode.scale
	parent.add_child(child, DebugSystem.shouldForceReadableName) # 性能：仅在调试时使用 force_readable_name
	child.owner = parent
	return child


## 返回 [param parentNode] 中与指定 [param type] 匹配的第一个子节点。
## 如果 [param includeParent] 为 `true`（默认），则如果 [param parentNode] 本身是匹配类型的节点，则可能返回它本身。这对于带有 `Entity.gd` 脚本的 [Sprite2D] 或 [Area2D] 等节点很有用。
static func findFirstChildOfType(parentNode: Node, childType: Variant, includeParent: bool = true) -> Node:
	if includeParent and is_instance_of(parentNode, childType):
		return parentNode

	var children: Array[Node] = parentNode.get_children()
	for child in children:
		if is_instance_of(child, childType): return child # break
	#else
	return null


## 调用 [method Tools.findFirstChildOfType] 返回 [param parentNode] 中与指定 [param types] 中任何一个匹配的第一个子节点（按数组顺序搜索）。
## 如果 [param includeParent] 为 `true`（默认），则在找不到任何请求的类型后返回 [param parentNode] 本身。
## 这对于选择实体的某些子节点进行操作很有用，例如 [AnimatedSprite2D] 或 [Sprite2D] 进行动画，否则在实体本身上操作。
## 性能：应该与按所需类型顺序多次调用 [method Tools.findFirstChildOfType] 相同。
static func findFirstChildOfAnyTypes(parentNode: Node, childTypes: Array[Variant], returnParentIfNoMatches: bool = true) -> Node:
	# 待定：更好的名字
	# 节点可能是多个继承类型的实例，因此检查每个请求的类型。
	# 注意：类型必须是外层循环，这样在搜索 [AnimatedSprite2D, Sprite2D] 时，会返回第一个 [AnimatedSprite2D]。
	# 如果子节点是外层循环，那么如果 [Sprite2D] 在子树中比 [AnimatedSprite2D] 更高，则可能返回 [Sprite2D]。
	for type: Variant in childTypes:
		for child in parentNode.get_children():
			if is_instance_of(child, type): return child # break

	# 在找不到任何请求的类型后返回父节点本身。
	# 设计：原因：这对于选择 [AnimatedSprite2D] 或 [Sprite2D] 否则在实体本身上操作的情况很有用。
	return parentNode if returnParentIfNoMatches else null


## 向上搜索树，直到找到匹配的父节点或祖父节点。
static func findFirstParentOfType(childNode: Node, parentType: Variant) -> Node:
	var parent: Node = childNode.get_parent() # parentOrGrandparent

	# 如果父节点不是匹配的类型，获取祖父节点（父节点的父节点）并继续向上搜索树，直到没有父节点（null）。
	while parent != null and not is_instance_of(parent, parentType): # 注意：避免在 `null` 上调用 get_parent()
		parent = parent.get_parent()

	return parent


## 递归地将指定 [param firstNode] 的所有子节点及其子子节点等追加到线性/"扁平化"列表中。
## 例如：`[FirstNode, Child1ofFirstNode, Child1ofChild1ofFirstNode, Child2ofChild1ofFirstNode, Child2ofFirstNode, …]`
## 提示：示例用法：这对于在树/列表等中设置 UI 焦点链很有用。
## @experimental
static func flatMapNodeTree(nodeToIterate: Node, existingList: Array[Node]) -> void:
	# 待办：更好的名字？
	# 待办：过滤
	# 待办：这应该是用于扁平化任何类型树的通用函数 :')
	existingList.append(nodeToIterate)
	for index in nodeToIterate.get_child_count(): # 不需要 -1，因为范围的结束是排他的
		flatMapNodeTree(nodeToIterate.get_child(index), existingList)


## 调用 [method Tools.flatMapNodeTree] 返回指定 [param firstNode] 的所有子节点及其子子节点的递归线性/"扁平化"列表。
## @experimental
static func getAllChildrenRecursively(firstNode: Node) -> Array[Node]:
	# 待定：与 flatMapNodeTree() 合并？
	var flatList: Array[Node]
	Tools.flatMapNodeTree(firstNode, flatList)
	return flatList


## 用另一个节点替换同一索引（顺序）的子节点，可选择复制位置、旋转和/或缩放。
## 注意：默认情况下不会删除先前的子节点及其子子节点。要删除子节点，请设置 [param freeReplacedChild] 或使用 [method Node.queue_free]。
## 返回：如果找到并替换了 [param childToReplace]，则返回 `true`。
static func replaceChild(parentNode: Node, childToReplace: Node, newChild: Node, copyPosition: bool = false, copyRotation: bool = false, copyScale: bool = false, freeReplacedChild: bool = false) -> bool:
	if childToReplace.get_parent() != parentNode:
		DebugSystem.printWarning(str("replaceChild() childToReplace.get_parent(): ", childToReplace.get_parent(), " != parentNode: ", parentNode))
		return false

	# 新子节点是否已经在另一个父节点中？
	# 待办：从现有父节点移除新子节点的选项
	var newChildCurrentParent: Node = newChild.get_parent()
	if newChildCurrentParent != null and newChildCurrentParent != parentNode:
		DebugSystem.printWarning("replaceChild(): newChild already in another parent: " + str(newChild, " in ", newChildCurrentParent))
		return false

	# 复制属性
	if copyPosition: newChild.position	= childToReplace.position
	if copyRotation: newChild.rotation	= childToReplace.rotation
	if copyScale:	 newChild.scale		= childToReplace.scale

	# 交换子节点
	var previousChildIndex: int = childToReplace.get_index() # 原始索引
	parentNode.remove_child(childToReplace) # 注意：不要使用 `replace_by()`，因为它也会转移所有子子节点。

	Tools.addChildAndSetOwner(newChild, parentNode) # 确保持久化
	parentNode.move_child(newChild, previousChildIndex)
	newChild.owner = parentNode # 信息：对于保存/加载时持久化到 [PackedScene] 是必需的。

	# 丢弃被移除的子节点？
	if freeReplacedChild: childToReplace.queue_free()

	return true


## 移除 [param parentNode] 的第一个子节点（如果有），并添加指定的 [param newChild]。可选择复制位置、旋转和/或缩放。
## 注意：无论父节点是否已有子节点，都会添加新子节点。
## 注意：默认情况下不会删除先前的子节点及其子子节点。要删除子节点，请设置 [param freeReplacedChild] 或使用 [method Node.queue_free]。
static func replaceFirstChild(parentNode: Node, newChild: Node, copyPosition: bool = false, copyRotation: bool = false, copyScale: bool = false, freeReplacedChild: bool = false) -> void:
	var childToReplace: Control = parentNode.findFirstChildControl()
	# DebugSystem.printDebug(str("replaceFirstChildControl(): ", childToReplace, " → ", newChild), parentNode)

	if childToReplace:
		Tools.replaceChild(parentNode, childToReplace, newChild, copyPosition, copyRotation, copyScale, freeReplacedChild)
	else: # 如果没有子节点，只需添加新的。
		Tools.addChildAndSetOwner(newChild, parentNode) # 确保持久化
		newChild.owner = parentNode # 用于持久化


## 从 [parameter parent] 移除每个子节点，然后在子节点上调用 [method Node.queue_free]。
## 返回：移除的子节点数量。
static func removeAllChildren(parent: Node) -> int:
	var removalCount: int = 0

	for child in parent.get_children():
		parent.remove_child(child) # 待定：这需要吗？不会删除节点，与 queue_free() 不同
		child.queue_free()
		removalCount += 1

	return removalCount


## 将节点从一个父节点移动到另一个父节点，并返回所有成功重新设置父节点的子节点数组。
static func reparentNodes(currentParent: Node, nodesToTransfer: Array[Node], newParent: Node, keepGlobalTransform: bool = true) -> Array[Node]:
	var transferredNodes: Array[Node]
	for node in nodesToTransfer:
		if node.get_parent() == currentParent: # 待定：这额外的"安全"层是否必要？
			node.reparent(newParent, keepGlobalTransform)
			node.owner = newParent # 用于持久化等
			if node.get_parent() == newParent: # 待定：此验证是否必要？
				transferredNodes.append(node)
			else:
				DebugSystem.printWarning(str("transferNodes(): ", node, " could not be moved from ", currentParent, " to newParent: ", newParent), node)
				continue
		else:
			DebugSystem.printWarning(str("transferNodes(): ", node, " does not belong to currentParent: ", currentParent), node)
			continue
	return transferredNodes


## 搜索一组节点并返回最接近指定参考位置的节点。
## 比较 [member Node2D.global_position]。
## 提示：可用于查找怪物要追逐的最接近的玩家，或寻的导弹武器要攻击的最接近的怪物等。
static func findNearestNodeInGroup(referencePosition: Vector2, targetGroup: StringName) -> Node2D:
	# 注意：使用 Engine.get_main_loop() 而不是 Node.get_tree()
	# 因为当由 ChaseComponent 等调用时，父实体可能尚未在 SceneTree 中
	var nodesInGroup: Array[Node] = Engine.get_main_loop().get_nodes_in_group(targetGroup)
	if nodesInGroup.is_empty(): return null

	var nearestNode:		Node2D  = null
	var minimumDistance:	float   = INF # 从无穷大开始
	var checkingDistance:	float

	for nodeToCheck in nodesInGroup:
		if nodeToCheck is Node2D:
			checkingDistance = referencePosition.distance_squared_to(nodeToCheck.global_position) # 性能：distance_squared_to() 比 distance_to() 更快
			if is_zero_approx(checkingDistance):
				return nearestNode # 无法比 0 更接近！
			elif checkingDistance < minimumDistance:
				minimumDistance = checkingDistance
				nearestNode = nodeToCheck

	return nearestNode


## 返回从节点的本地坐标转换到全局位置的 [Rect2] 副本。
## 提示：性能：此函数可以用 `Rect2(rect.position + node.global_position, rect.size)` 替换以避免额外调用。
## 提示：与 [member getShapeBoundsInNode] 的输出结合使用以获取 [Area2D] 的全局区域。
## 警告：可能无法正确处理旋转、缩放或负维度。
static func convertNodeRectToGlobalCoordinates(node: CanvasItem, rect: Rect2) -> Rect2:
	# 待办：考虑旋转和缩放
	return Rect2(rect.position + node.global_position, rect.size)

#endregion


#region NodePath Functionss

## 将 [NodePath] 从 `./` 形式转换为绝对表示：`/root/`，包括属性路径（如果有）。
static func convertRelativeNodePathToAbsolute(parentNodeToConvertFrom: Node, relativePath: NodePath) -> NodePath:
	var absoluteNodePath: String = parentNodeToConvertFrom.get_node(relativePath).get_path()
	var propertyPath: String = str(":", relativePath.get_concatenated_subnames())
	var absolutePathIncludingProperty: NodePath = NodePath(str(absoluteNodePath, propertyPath))

	# DebugSystem:
	#DebugSystem.printLog(str("Tools.convertRelativeNodePathToAbsolute() parentNodeToConvertFrom: ", parentNodeToConvertFrom, \
		#", relativePath: ", relativePath, \
		#", absoluteNodePath: ", absoluteNodePath, \
		#", propertyPath: ", propertyPath))

	return absolutePathIncludingProperty


## 将 [NodePath] 拆分为 2 个路径的数组，其中索引 [0] 是节点的路径，[1] 是属性链，例如 `/root:size:x` → [`/root`, `:size:x`]
static func splitPathIntoNodeAndProperty(path: NodePath) -> Array[NodePath]:
	var nodePath: NodePath
	var propertyPath: NodePath

	nodePath = NodePath(str("/" if path.is_absolute() else "", path.get_concatenated_names()))
	propertyPath = NodePath(str(":", path.get_concatenated_subnames()))

	return [nodePath, propertyPath]

#endregion


#region Area & Shape Geometry

static func getRectCorner(rectangle: Rect2, compassDirection: Vector2i) -> Vector2:
	var position:	Vector2 = rectangle.position
	var center:		Vector2 = rectangle.get_center()
	var end:		Vector2 = rectangle.end

	match compassDirection:
		CompassVectors.northWest:	return Vector2(position.x, position.y)
		CompassVectors.north:		return Vector2(center.x, position.y)
		CompassVectors.northEast:	return Vector2(end.x, position.y)
		CompassVectors.east:		return Vector2(end.x, center.y)
		CompassVectors.southEast:	return Vector2(end.x, end.y)
		CompassVectors.south:		return Vector2(center.x, end.y)
		CompassVectors.southWest:	return Vector2(position.x, end.y)
		CompassVectors.west:		return Vector2(position.x, center.y)

		_: return Vector2.ZERO


## 返回表示 [CollisionObject2D]（例如 [Area2D] 或 [CharacterBody2D]）的第一个 [CollisionShape2D] 子节点的边界/范围的 [Rect2]。
## 注意：矩形在形状的 [CollisionShape2D] 容器的坐标中，其锚点在中心。
## 对于具有单个 [RectangleShape2D] 的区域最准确可靠。
## 返回：边界的 [Rect2]。失败时：大小为 -1 且位置设置为 [CollisionObject2D] 的本地位置的矩形。
static func getShapeBounds(node: CollisionObject2D) -> Rect2:
	# 技巧：唉，Godot 让这变得如此困难...

	# 查找 CollisionShape2D 子节点。
	var shapeNode: CollisionShape2D = findFirstChildOfType(node, CollisionShape2D)

	if not shapeNode:
		DebugSystem.printWarning("getShapeBounds(): Cannot find a CollisionShape2D child", node)
		return Rect2(node.position.x, node.position.y, -1, -1) # 返回与节点原点匹配的无效负大小矩形。

	return shapeNode.shape.get_rect()


## 返回表示 [CollisionObject2D]（例如 [Area2D] 或 [CharacterBody2D]）的所有 [CollisionShape2D] 子节点的合并矩形边界/范围的 [Rect2]。
## 要仅获取第一个形状的边界，请将 [param maximumShapeCount] 设置为 1。
## 注意：矩形在 [CollisionObject2D] 的本地坐标中。要转换为全局坐标，请加上区域的 [member Node2D.global_position]。
## 对于具有单个 [RectangleShape2D] 的区域/体最准确可靠。
## 返回：所有合并边界的 [Rect2]。失败时：大小为 -1 且位置设置为 [CollisionObject2D] 的本地位置的矩形。
static func getShapeBoundsInNode(node: CollisionObject2D, maximumShapeCount: int = 100) -> Rect2:
	# 待定：性能：缓存结果的选项？
	# 技巧：唉，Godot 让这变得如此困难...

	# 信息：计划：概述：[CollisionObject2D] 有一个 [CollisionShape2D] 子 [Node]，它又有一个 [Shape2D] [Resource]。
	# 在父 CollisionObject2D 中，CollisionShape2D 的"锚点"在左上角，因此其 `position` 可能是 0,0。
	# 但在 CollisionShape2D 内部，Shape2D 的锚点在形状的中心，因此对于 32x32 的矩形，其 `position` 例如是 16,16。
	# 所以，我们必须计算 Shape2D 在 CollisionObject2D 坐标空间中的矩形。
	# 然后将其转换为全局坐标。

	if node.get_child_count() < 1: return Rect2(node.position.x, node.position.y, -1, -1) # 如果失败，返回与节点原点匹配的无效负大小矩形。

	# 获取所有 CollisionShape2D 子节点

	var combinedShapeBounds: Rect2
	var shapesAdded: int = 0
	var shapeSize:	 Vector2
	var shapeBounds: Rect2

	for shapeNode in node.get_children(): # 待定：性能：使用 Node.find_children()？
		if shapeNode is CollisionShape2D:
			shapeSize = shapeNode.shape.get_rect().size # 待定：我们应该使用 `extents` 吗？它似乎是大小的一半，但它似乎是一个隐藏属性 [截至 4.3 Dev 3]。
			# 因为 [CollisionShape2D] 的锚点在中心，我们必须通过减去实际形状大小的一半来获取其左上角：
			shapeBounds = Rect2(shapeNode.position - shapeSize / 2, shapeSize) # 待定：性能：使用 * 0.5？

			if shapesAdded < 1: combinedShapeBounds = shapeBounds # 是第一个形状吗？
			else: combinedShapeBounds.merge(shapeBounds)

			# 调试：Debug.printDebug(str("shape: ", shapeNode.shape, ", rect: ", shapeNode.shape.get_rect(), ", bounds in node: ", shapeBounds, ", combinedShapeBounds: ", combinedShapeBounds), node)
			shapesAdded += 1
			if shapesAdded >= maximumShapeCount: break

	if shapesAdded < 1:
		DebugSystem.printWarning("getShapeBoundsInNode(): Cannot find a CollisionShape2D child", node)
		return Rect2(node.position.x, node.position.y, -1, -1)
	else:
		# 调试：Debug.printTrace([combinedShapeBounds, node.get_child_count(), shapesAdded], node)
		return combinedShapeBounds


## 调用 [method Tools.getShapeBoundsInNode] 并返回表示 [CollisionObject2D]（例如 [Area2D] 或 [CharacterBody2D]）的所有 [CollisionShape2D] 子节点的合并矩形边界/范围的 [Rect2]，转换为全局坐标。
## 对于比较 2 个独立节点/实体的 [Area2D] 等很有用。
static func getShapeGlobalBounds(node: CollisionObject2D) -> Rect2:
	# 待定：性能：缓存结果的选项？
	var shapeGlobalBounds: Rect2 = getShapeBoundsInNode(node)
	shapeGlobalBounds.position   = node.to_global(shapeGlobalBounds.position)
	return shapeGlobalBounds


## 返回表示内部/"包含的" [Rect2] 超出外部/"容器" [Rect2] 的距离的 [Vector2]，例如玩家的 [ClimbComponent] 相对于可攀爬的 [Area2D] "梯子"等。
## 提示：要将内部矩形放回容器矩形内，从 [param containedRect] 的 [member Rect2.position]（或从它表示的实体的位置）减去（或加上负值）返回的偏移量。
## 警告：不包括旋转或缩放等。
## 返回：[param containedRect] 超出 [param containerRect] 边界的偏移/位移。
## 负 -X 值表示向左，+X 表示向右。-Y 表示向上突出，+Y 表示向下。
## 如果 [param containedRect] 完全在 [param containerRect] 内，则为 (0,0)。
static func getRectOffsetOutsideContainer(containedRect: Rect2, containerRect: Rect2) -> Vector2:
	# If the container completely encloses the containee, no need to do anything.
	if containerRect.encloses(containedRect): return Vector2.ZERO

	var displacement: Vector2

	# 向左突出？
	if containedRect.position.x < containerRect.position.x:
		displacement.x = containedRect.position.x - containerRect.position.x # 如果被包含者的左边缘更靠左则为负
	# 向右突出？
	elif containedRect.end.x > containerRect.end.x:
		displacement.x = containedRect.end.x - containerRect.end.x # 如果被包含者的右边缘更靠右则为正

	# 向上突出？
	if containedRect.position.y < containerRect.position.y:
		displacement.y = containedRect.position.y - containerRect.position.y # 如果被包含者的顶部更高则为负
	# 向下突出？
	elif containedRect.end.y > containerRect.end.y:
		displacement.y = containedRect.end.y - containerRect.end.y # 如果被包含者的底部更低则为正

	return displacement


## 检查 [Rect2] 列表并返回最接近指定参考矩形的矩形。
## [param comparedRects] 通常表示静态"区域"，[param referenceRect] 可能是玩家实体或另一个角色的边界等。
static func findNearestRect(referenceRect: Rect2, comparedRects: Array[Rect2]) -> Rect2:
	# 待定：性能：缓存结果的选项？

	var nearestRect:	 Rect2
	var minimumDistance: float = INF # 从无穷大开始

	# 待定：性能：所有这些变量都可以通过直接访问 Rect2.position 和 Rect2.end 等来替换，但这些名称可能使代码更易于阅读和理解。

	var referenceLeft:	float = referenceRect.position.x
	var referenceRight:	float = referenceRect.end.x
	var referenceTop:	float = referenceRect.position.y
	var referenceBottom:float = referenceRect.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # 区域边缘之间的像素
	var distance:		float	# 边缘之间的欧几里得距离

	for comparedRect: Rect2 in comparedRects:
		if not comparedRect.abs().has_area(): continue # 如果矩形没有区域则跳过

		# 如果两个区域完全相同的位置和大小，
		# 或者其中一个完全包含另一个，那么无法比这更接近了！
		if comparedRect.is_equal_approx(referenceRect) \
		or comparedRect.encloses(referenceRect) or referenceRect.encloses(comparedRect):
			minimumDistance = 0
			nearestRect = comparedRect
			break

		# 简化名称
		comparedLeft	= comparedRect.position.x
		comparedRight	= comparedRect.end.x
		comparedTop		= comparedRect.position.y
		comparedBottom	= comparedRect.end.y
		gap				= Vector2.ZERO # 如果边缘接触，间隙将默认为 0

		# 计算水平间隙
		if   referenceRight < comparedLeft:  gap.x = comparedLeft  - referenceRight	# 主要区域在比较区域的左侧？
		elif comparedRight  < referenceLeft: gap.x = referenceLeft - comparedRight	# 还是在右侧？

		# 计算垂直间隙
		if   referenceBottom < comparedTop:	 gap.y = comparedTop  - referenceBottom	# 主要区域在比较区域上方？
		elif comparedBottom  < referenceTop: gap.y = referenceTop - comparedBottom	# 还是在下方？

		# 获取边缘之间的欧几里得距离
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# 如果这是新的最小值，我们有一个更近的 `nearestRect`
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestRect = comparedRect

	return nearestRect


## 检查 [Area2D] 列表并返回最接近指定参考区域的区域。
## [param comparedAreas] 通常表示静态"区域"，[param referenceArea] 可能是玩家实体或另一个角色的边界等。
## 注意：如果 2 个不同的 [Area2D] 与 [param referenceArea] 的距离相同，则使用位于顶部的一个，即具有更高 [member CanvasItem.z_index] 的那个。
static func findNearestArea(referenceArea: Area2D, comparedAreas: Array[Area2D]) -> Area2D:
	# 待定：性能：缓存结果的选项？

	# 设计：性能：不能使用 findNearestRect()，因为那需要事先在所有区域上调用 getShapeGlobalBounds()，
	# 并且有一个基于 Z 索引的单独平局决胜，所以必须有一些代码重复 :')

	var nearestArea:	Area2D = null # 初始化为 `null` 以避免"在赋值前使用"警告
	var minimumDistance: float = INF  # 从无穷大开始

	var referenceAreaBounds: Rect2 = Tools.getShapeGlobalBounds(referenceArea)
	var comparedAreaBounds:  Rect2

	# 待定：性能：所有这些变量都可以通过直接访问 Rect2.position 和 Rect2.end 等来替换，但这些名称可能使代码更易于阅读和理解。

	var referenceLeft:	float = referenceAreaBounds.position.x
	var referenceRight:	float = referenceAreaBounds.end.x
	var referenceTop:	float = referenceAreaBounds.position.y
	var referenceBottom:float = referenceAreaBounds.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # 区域边缘之间的像素
	var distance:		float	# 边缘之间的欧几里得距离

	for comparedArea: Area2D in comparedAreas:
		if comparedArea == referenceArea: continue

		comparedAreaBounds = Tools.getShapeGlobalBounds(comparedArea)
		if not comparedAreaBounds.abs().has_area(): continue # 如果区域没有区域则跳过！

		# 如果两个区域完全相同的位置和大小，
		# 或者其中一个完全包含另一个，那么无法比这更接近了！
		if comparedAreaBounds.is_equal_approx(referenceAreaBounds) \
		or comparedAreaBounds.encloses(referenceAreaBounds) or referenceAreaBounds.encloses(comparedAreaBounds):
			# 这是第一个重叠区域吗？（即最小距离还不是 0）
			# 还是另一个在视觉上位于先前重叠区域顶部（具有更高 Z 索引）的重叠区域？
			if not is_zero_approx(minimumDistance) \
			or (nearestArea and comparedArea.z_index > nearestArea.z_index):
				minimumDistance = 0
				nearestArea = comparedArea
			continue # 注意：不要在这里 `break` 循环！继续检查多个重叠区域以选择具有最高 Z 索引的那个。

		# 简化名称
		comparedLeft	= comparedAreaBounds.position.x
		comparedRight	= comparedAreaBounds.end.x
		comparedTop		= comparedAreaBounds.position.y
		comparedBottom	= comparedAreaBounds.end.y
		gap				= Vector2.ZERO # 如果边缘接触，间隙将默认为 0

		# 计算水平间隙
		if   referenceRight < comparedLeft:  gap.x = comparedLeft  - referenceRight	# 主要区域在比较区域的左侧？
		elif comparedRight  < referenceLeft: gap.x = referenceLeft - comparedRight	# 还是在右侧？

		# 计算垂直间隙
		if   referenceBottom < comparedTop:	 gap.y = comparedTop  - referenceBottom	# 主要区域在比较区域上方？
		elif comparedBottom  < referenceTop: gap.y = referenceTop - comparedBottom	# 还是在下方？

		# 获取边缘之间的欧几里得距离
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# 如果这是新的最小值，我们有一个更近的 `nearestArea`
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestArea = comparedArea

		# 如果 2 个不同的 [Area2D] 具有相同的距离，
		# 使用在视觉上位于另一个顶部的那个：具有更高 Z 索引
		elif is_equal_approx(distance, minimumDistance) \
		and nearestArea and comparedArea.z_index > nearestArea.z_index:
			nearestArea = comparedArea
		# 待定：否则，保留第一个区域。

	return nearestArea


## 返回 [Area2D] 的所有 [Shape2D] 的合并矩形边界内的随机点。
## 注意：不验证点是否实际包含在 [Shape2D] 内。
## 对于具有单个 [RectangleShape2D] 的区域最准确可靠。
static func getRandomPositionInArea(area: Area2D) -> Vector2:
	var areaBounds: Rect2 = getShapeBoundsInNode(area)

	# 在区域内生成随机位置。

	#randomize() # 待定：我们需要这个吗？

	#var isWithinArea: bool = false
	#while not isWithinArea:

	var x: float = randf_range(areaBounds.position.x, areaBounds.end.x)
	var y: float = randf_range(areaBounds.position.y, areaBounds.end.y)
	var randomPosition: Vector2 = Vector2(x, y)

	#if shouldVerifyWithinArea: isWithinArea = ... # 待办：无法检查点是否在区域内 :( [截至 4.3 Dev 3]
	#else: isWithinArea = true

	# 调试：Debug.printDebug(str("area: ", area, ", areaBounds: ", areaBounds, ", randomPosition: ", randomPosition))
	return randomPosition


## 返回在指定 [enum CompassDirection] 中移动的 [Vector2i] 的副本
static func offsetVectorByCompassDirection(vector: Vector2i, direction: CompassDirection) -> Vector2i:
	return vector + Tools.compassDirectionVectors[direction]

#endregion


#region Physics Functions

## 如果 [method CharacterBody2D.get_last_motion()] 在相应轴上为 0，则将 [member CharacterBody2D.velocity] 的 X 和/或 Y 分量设置为 0。
## 这防止了"粘附效应"，即如果玩家在角色被推到墙上时继续输入方向，
## 当速度从墙的方向逐渐改变为远离墙时，向另一个方向移动会有明显的延迟。
static func resetBodyVelocityIfZeroMotion(body: CharacterBody2D) -> Vector2:
	var lastMotion: Vector2 = body.get_last_motion()
	if is_zero_approx(lastMotion.x): body.velocity.x = 0
	if is_zero_approx(lastMotion.y): body.velocity.y = 0
	return lastMotion


## 从基于 [CollisionObject2D] 的节点（例如 [Area2D] 或 [CharacterBody2D]）和给定的"形状索引"返回 [Shape2D]
## @experimental
static func getCollisionShape(node: CollisionObject2D, shapeIndex: int = 0) -> Shape2D:
	# 这是什么地狱...
	var areaShapeOwnerID: int = node.shape_find_owner(shapeIndex)
	# 未使用：var areaShapeOwner: CollisionShape2D = node.shape_owner_get_owner(areaShapeOwnerID)
	return node.shape_owner_get_shape(areaShapeOwnerID, shapeIndex) # 检查：应该是 `shapeIndex` 还是 0？

#endregion


#region Visual Functions

## 返回用于修改节点的全局位置的偏移量，以将其限制在距另一个节点的最大距离/半径（任何方向）内。
## 如果 [param nodeToClamp] 在 [param anchor] 的 [param maxDistance] 内，则返回 (0,0)，即不需要移动。
## 可用于将视觉效果（例如瞄准光标）系到锚点（例如角色精灵），如 [AimingCursorComponent] 和 [TetherComponent] 中。
## 注意：不返回直接位置，因此必须通过 `+=` 而不是 `=` 更新 [param nodeToClamp] 的 `global_position`！
static func clampPositionToAnchor(nodeToClamp: Node2D, anchor: Node2D, maxDistance: float) -> Vector2:
	var difference:	Vector2 = nodeToClamp.global_position - anchor.global_position # 使用全局位置，以防是父子关系，例如视觉组件保持在其实体附近。
	var distance:	float   = difference.length()

	if distance > maxDistance:
		var offset: Vector2 = difference.normalized() * maxDistance
		return (anchor.global_position + offset) - nodeToClamp.global_position
	else:
		return Vector2.ZERO


## 返回一个 [Color]，其 R、G、B 分别设置为"量化"为 0.25 步长的随机值
static func getRandomQuantizedColor() -> Color:
	const steps: Array[float] = [0.25, 0.5, 0.75, 1.0]
	return Color(steps.pick_random(), steps.pick_random(), steps.pick_random())


## 返回在节点的视口上居中的指定"设计大小"。
## 注意：视口大小可能与缩放的屏幕/窗口大小不同。
static func getCenteredPositionOnViewport(node: Node2D, designWidth: float, designHeight: float) -> Vector2:
	# 待定：更好的名字？
	# 必须指定"设计大小"，因为很难获取实际大小，考虑缩放等。
	var viewport: Rect2		= node.get_viewport_rect() # 首先查看视口大小
	var center: Vector2		= Vector2(viewport.size.x / 2.0, viewport.size.y / 2.0) # 获取视口中心
	var designSize: Vector2	= Vector2(designWidth, designHeight) # 获取节点设计大小
	return center - (designSize / 2.0) # 在视口上居中大小


static func addRandomDistance(position: Vector2,    \
minimumDistance: Vector2, maximumDistance: Vector2, \
xScale: float = 1.0, yScale: float = 1.0) -> Vector2:

	var randomizedPosition: Vector2 = position
	randomizedPosition.x += randf_range(minimumDistance.x, maximumDistance.x) * xScale
	randomizedPosition.y += randf_range(minimumDistance.y, maximumDistance.y) * yScale
	return randomizedPosition

## 返回相机视图中屏幕左上角的全局位置。
static func getScreenTopLeftInCamera(camera: Camera2D) -> Vector2:
	var cameraCenter: Vector2 = camera.get_screen_center_position()
	return cameraCenter - camera.get_viewport_rect().size / 2


## 注意：不会将新副本添加到原始节点的父节点。请跟进 [method Tools.addChildAndSetOwner]。
## 默认标志：DUPLICATE_SIGNALS + DUPLICATE_GROUPS + DUPLICATE_SCRIPTS + DUPLICATE_USE_INSTANTIATION
static func createScaledCopy(nodeToDuplicate: Node2D, copyScale: Vector2, flags: int = 15) -> Node2D:
	var scaledCopy: Node2D = nodeToDuplicate.duplicate(flags)
	scaledCopy.scale = copyScale
	return scaledCopy


#endregion


#region Tile Map Functions

static func getCellGlobalPosition(map: TileMapLayer, coordinates: Vector2i) -> Vector2:
	var cellPosition: Vector2 = map.map_to_local(coordinates)
	var cellGlobalPosition: Vector2 = map.to_global(cellPosition)
	return cellGlobalPosition


## 有关自定义数据层名称列表，请参阅 [Global.TileMapCustomData]。
static func getTileData(map: TileMapLayer, coordinates: Vector2i, dataName: StringName) -> Variant:
	var tileData: TileData = map.get_cell_tile_data(coordinates)
	return tileData.get_custom_data(dataName) if tileData else null


## 获取 [TileMapCellData] 的单个单元格的自定义数据。
## 注意：单元格与图块不同；图块是 [TileSet] 用于绘制 [TileMapLayer] 的多个单元格的资源。
## 设计：这是在 [TileMapCellData] 之上的单独函数，因为它将来可能重定向到原生 Godot 功能。
static func getCellData(map: TileMapLayerWithCellData, coordinates: Vector2i, key: StringName) -> Variant:
	return map.getCellData(coordinates, key)


## 设置 [TileMapLayerWithCellData] 的单个单元格的自定义数据。
## 注意：单元格与图块不同；图块是 [TileSet] 用于绘制 [TileMapLayer] 的多个单元格的资源。
## 设计：这是在 [TileMapLayerWithCellData] 之上的单独函数，因为它将来可能重定向到原生 Godot 功能。
static func setCellData(map: TileMapLayerWithCellData, coordinates: Vector2i, key: StringName, value: Variant) -> void:
	map.setCellData(coordinates, key, value)


## 使用自定义数据结构检查单个 [TileMap] 单元格（不是图块）是否被 [Entity] 占用并返回它。
## 注意：不首先检查 [member Global.TileMapCustomData.isOccupied]，仅检查 [member Global.TileMapCustomData.occupant]
static func getCellOccupant(data: TileMapCellData, coordinates: Vector2i) -> Entity:
	return data.getCellData(coordinates, GlobalSystem.TileMapCustomData.occupant)


## 使用自定义数据结构将单个 [TileMap] 单元格（不是图块）标记为被 [Entity] 占用或未占用。
static func setCellOccupancy(data: TileMapCellData, coordinates: Vector2i, isOccupied: bool, occupant: Entity) -> void:
	data.setCellData(coordinates, GlobalSystem.TileMapCustomData.isOccupied, isOccupied)
	data.setCellData(coordinates, GlobalSystem.TileMapCustomData.occupant, occupant if isOccupied else null)


static func checkTileAndCellVacancy(map: TileMapLayer, data: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	# CHECK: First check the CELL data because it's quicker, right?
	var isCellVacant: bool = Tools.checkCellVacancy(data, coordinates, ignoreEntity)
	if not isCellVacant: return false # If there is an occupant, no need to check the Tile data, just scram

	# Then check the TILE data
	var isTileVacant: bool = Tools.checkTileVacancy(map, coordinates)

	return isCellVacant and isTileVacant


## 通过检查自定义图块/单元格数据中的标志（如 [constant Global.TileMapCustomData.isWalkable]）来检查指定图块是否空闲。
static func checkTileVacancy(map: TileMapLayer, coordinates: Vector2i) -> bool:
	var isTileVacant: bool = false

	# 注意：设计：缺失值应被视为 `true` 以帮助快速原型设计
	# 待办：以更优雅的方式检查所有这些

	var tileData: 	TileData = map.get_cell_tile_data(coordinates)
	var isWalkable:	Variant
	var isBlocked:	Variant

	if tileData:
		isWalkable = tileData.get_custom_data(GlobalSystem.TileMapCustomData.isWalkable)
		isBlocked  = tileData.get_custom_data(GlobalSystem.TileMapCustomData.isBlocked)

	if map is TileMapLayerWithCellData and map.debugMode: DebugSystem.printDebug(str("tileData[isWalkable]: ", isWalkable, ", [isBlocked]: ", isBlocked))

	# 如果没有数据，假设图块始终空闲。
	isTileVacant = (isWalkable or isWalkable == null) and (not isBlocked or isWalkable == null)

	return isTileVacant


## 通过检查自定义图块/单元格数据中的标志（如 [constant Global.TileMapCustomData.isWalkable]）来检查指定图块是否空闲。
static func checkCellVacancy(mapData: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	var isCellVacant: bool = false

	# 首先检查单元格数据，因为它更快

	var cellDataOccupied: Variant = mapData.getCellData(coordinates, GlobalSystem.TileMapCustomData.isOccupied) # 注意：不应该是 `bool`，这样如果缺失可以是 `null`，而不是缺失时为 `false`。
	var cellDataOccupant: Entity  = mapData.getCellData(coordinates, GlobalSystem.TileMapCustomData.occupant)

	if mapData.debugMode: DebugSystem.printDebug(str("checkCellVacancy() ", mapData, " @", coordinates, " cellData[cellDataOccupied]: ", cellDataOccupied, ", occupant: ", cellDataOccupant))

	if cellDataOccupied is bool:
		isCellVacant = not cellDataOccupied or cellDataOccupant == ignoreEntity
	else:
		# 如果没有数据，假设单元格始终未被占用。
		isCellVacant = true

	# 如果有占用者，无需检查图块数据，直接返回
	if not isCellVacant: return false

	return isCellVacant


## 验证给定坐标是否在指定 [TileMapLayer] 的网格内。
static func checkTileMapCoordinates(map: TileMapLayer, coordinates: Vector2i) -> bool:
	var gridRect: Rect2i = map.get_used_rect()
	return gridRect.has_point(coordinates)


## 返回包含所有"已使用"或"已绘制"单元格的 [TileMapLayer] 的矩形边界，在 TileMap 父节点的坐标空间中。
## 警告：这可能不对应于单元格/图块的视觉位置，即它忽略单个图块的 [member TileData.texture_origin] 属性。
static func getTileMapScreenBounds(map: TileMapLayer) -> Rect2: # 待定：重命名为 getTileMapBounds()？
	var cellGrid:	Rect2 = Rect2(map.get_used_rect()) # 将整数 `Rect2i` 转换为浮点数以简化计算
	if not cellGrid.has_area(): return Rect2() # 如果没有单元格，则返回空区域

	var screenRect:	Rect2
	var tileSize:	Vector2 = Vector2(map.tile_set.tile_size) # 将整数 `Vector2i` 转换为浮点数以简化计算

	# 点最初将在 TileMap 自己的空间中
	screenRect.position  = cellGrid.position * tileSize
	screenRect.size		 = cellGrid.size * tileSize

	# 通过地图在地图父节点空间中的位置来偏移边界
	screenRect.position += map.position

	return screenRect


## 检查 [Vector2] 是否在 [TileMapLayer] 内。
## 重要：[param point] 必须在 [param map] 的父节点的坐标空间中。请参阅 [method Node2D.to_local]。
## 警告：基于浮点数的内部位置可能具有像 0.5 等的小数值，这可能导致计算结果与屏幕上的视觉效果不匹配，例如交集可能返回 false。
static func isPointInTileMap(point: Vector2, map: TileMapLayer) -> bool:
	# 注意：显然不需要将 Rect2 的右边缘和底边缘增长 1 像素，即使 Rect2.has_point() 不包括这些边缘上的点，根据 Godot 文档。
	return Tools.getTileMapScreenBounds(map).has_point(point)


## 检查 [Rect2] 的 [member Rect2.position] 原点和/或 [member Rect2.end] 点是否在 [TileMapLayer] 内。
## 如果 [param checkOriginAndEnd] 为 `true`（默认），则此方法仅在矩形的原点和终点都完全在 TileMap 内时返回 `true`。
## 如果 [param checkOriginAndEnd] 为 `false`，则即使部分交集也返回 `true`。
## 重要：[param rectangle] 必须在 [param map] 的父节点的坐标空间中。请参阅 [method Node2D.to_local]。
## 注意：不支持旋转和其他变换。
## 警告：基于浮点数的内部位置可能具有像 0.5 等的小数值，这可能导致计算结果与屏幕上的视觉效果不匹配，例如交集可能返回 false。
static func isRectInTileMap(rectangle: Rect2, map: TileMapLayer, checkOriginAndEnd: bool = true) -> bool:
	var tileMapBounds: Rect2 = Tools.getTileMapScreenBounds(map)
	return tileMapBounds.encloses(rectangle) if checkOriginAndEnd else rectangle.intersects(tileMapBounds)


## 检查 [TileMapLayer] 和物理体在指定图块坐标处的碰撞。
## 警告：未实现：将始终返回 `true`。目前似乎还没有办法在 Godot 中轻松检查这一点。
## @experimental
static func checkTileCollision(map: TileMapLayer, _body: PhysicsBody2D, _coordinates: Vector2i) -> bool:
	# 如果 TileMap 或其碰撞被禁用，则图块始终可用。
	if not map.enabled or not map.collision_enabled: return true
	return true # 技巧：待办：实现


## 将 [TileMap] 单元格坐标从 [param sourceMap] 转换为 [param destinationMap]。
## 转换通过首先将单元格坐标转换为像素/屏幕坐标来执行。
static func convertCoordinatesBetweenTileMaps(sourceMap: TileMapLayer, cellCoordinatesInSourceMap: Vector2i, destinationMap: TileMapLayer) -> Vector2i:

	# 1：将源 TileMap 的单元格坐标转换为像素（屏幕）坐标，在源地图的空间中。
	# 注意：这可能不对应于图块的视觉位置；它忽略单个图块的 `TileData.texture_origin`。
	var pixelPositionInSourceMap: Vector2 = sourceMap.map_to_local(cellCoordinatesInSourceMap)

	# 2：将像素位置转换为全局空间
	var globalPosition: Vector2 = sourceMap.to_global(pixelPositionInSourceMap)

	# 3：将全局位置转换为目标 TileMap 的空间
	var pixelPositionInDestinationMap: Vector2 = destinationMap.to_local(globalPosition)

	# 4：将像素位置转换为目标地图的单元格坐标
	var cellCoordinatesInDestinationMap: Vector2i = destinationMap.local_to_map(pixelPositionInDestinationMap)

	DebugSystem.printDebug(str("Tools.convertCoordinatesBetweenTileMaps() ", sourceMap, " @", cellCoordinatesInSourceMap, " → sourcePixel: ", pixelPositionInSourceMap, " → globalPixel: ", globalPosition, " → destinationPixel: ", pixelPositionInDestinationMap, " → @", cellCoordinatesInDestinationMap, " ", destinationMap))
	return cellCoordinatesInDestinationMap


## 如果 [TileMapLayer] 单元格是 [member Global.TileMapCustomData.isDestructible]，则损坏它。
## 如果有 [member Global.TileMapCustomData.nextTileOnDamage]，则将单元格的图块更改为它，
## 或者如果没有指定"下一个图块"或 X 和 Y 坐标都小于 0（即 (-1,-1)），则擦除单元格
## 如果单元格被损坏，返回 `true`。
## @experimental
static func damageTileMapCell(map: TileMapLayer, coordinates: Vector2i) -> bool:
	# 待办：可变生命值和伤害
	# 性能：不调用 Tools.getTileData() 以减少调用
	var tileData: TileData = map.get_cell_tile_data(coordinates)
	if tileData:
		var isDestructible: bool = tileData.get_custom_data(GlobalSystem.TileMapCustomData.isDestructible)
		if  isDestructible:
			var nextTileOnDamage: Vector2i = tileData.get_custom_data(GlobalSystem.TileMapCustomData.nextTileOnDamage)
			if nextTileOnDamage and (nextTileOnDamage.x >= 0 or nextTileOnDamage.y >= 0): # 两个负坐标都无效或表示"损坏时销毁"
				map.set_cell(coordinates, 0, nextTileOnDamage)
			else: map.erase_cell(coordinates)
			return true

	return false


## 从指定的网格范围返回 [TileMapLayer] 上的随机坐标数组。
## 警告：不要使用 [method TileMapLayer.get_used_rect()] [member Rect2i.size] 或 [member Rect2i.end]，因为它不是基于 0 的：它将在地图实际网格之外 +1！提示：使用 [method Rect2i.grow](-1)
static func findRandomTileMapCells(map: TileMapLayer,
selectionChance:  float = 1.0,
includeUsedCells:  bool = true,
includeEmptyCells: bool = true,
cellRegionStart: Vector2i = map.get_used_rect().position,
cellRegionEnd:   Vector2i = map.get_used_rect().grow(-1).end # Make `end` 0-based
) -> Array[Vector2i]:
	# TODO: Validate parameters and sizes
	# NOTE: Rect2i parameters are less intuitive because it uses width/height parameters for initialization, not direct end coordinates.

	if (not includeUsedCells and not includeEmptyCells) \
	or is_zero_approx(selectionChance) or selectionChance < 0 \
	or cellRegionEnd < cellRegionStart:
		return []

	var coordinates: Vector2i
	var isCellEmpty: bool
	var randomCells: Array[Vector2i]

	# CHECK: PERFORMANCE: What's faster? TileMapLayer.get_used_cells() & then filtering,
	# or building the list manually by iterating every cell?

	# NOTE: +1 to range() end to make the bounds inclusive
	for y in range(cellRegionStart.y, cellRegionEnd.y + 1):
		for x in range(cellRegionStart.x, cellRegionEnd.x + 1):

			# PERFORMANCE: Roll the chance before doing all the other checks and calculations
			if selectionChance < 1.0 and not randf() < selectionChance: continue # TBD: Should this be an integer?

			coordinates = Vector2i(x, y)

			# A cell is considered "empty" if its source & alternative identifiers are -1, and its atlas coordinates are (-1,-1).
			# TBD: PERFORMANCE: Do we need to check ALL 3?
			isCellEmpty = map.get_cell_source_id(coordinates)  == -1 \
				and map.get_cell_alternative_tile(coordinates) == -1 \
				and map.get_cell_atlas_coords(coordinates) == Vector2i(-1, -1)

			if (includeUsedCells  and not isCellEmpty) \
			or (includeEmptyCells and isCellEmpty):
				randomCells.append(Vector2i(x, y))

	return randomCells


## 使用地图 [TileSet] 图集中指定范围内的随机图块"重新绘制" [TileMapLayer] 中所有指定的单元格坐标。
## 提示：调用 [method findRandomTileMapCells] 以构建随机单元格数组。
static func randomizeTileMapCells(map: TileMapLayer, cellsToRepaint: Array[Vector2i], atlasCoordinatesMin: Vector2i, atlasCoordinatesMax: Vector2i) -> void:
	# 待办：验证图集大小
	# 注意：Rect2i 参数不太直观，因为它使用 width/height 参数进行初始化，而不是直接结束坐标。
	# 待定：性能：添加单独的 modificationChance 以获得额外控制，还是 findRandomTileMapCells() 的 selectionChance 足够？

	if not map \
	or cellsToRepaint.is_empty() \
	or atlasCoordinatesMax < atlasCoordinatesMin:
		return

	var randomTile:  Vector2i

	for cellCoordinates in cellsToRepaint:
		randomTile = Vector2i(
			randi_range(atlasCoordinatesMin.x, atlasCoordinatesMax.x),
			randi_range(atlasCoordinatesMin.y, atlasCoordinatesMax.y))
		map.set_cell(cellCoordinates, 0, randomTile)


## 创建指定场景的实例副本，并将它们放置在 [TileMapLayer] 的单元格上，每个在网格中的唯一位置。
## 返回创建的节点的 [Dictionary]，以它们的单元格坐标作为键。
## 提示：要在特定单元格坐标处生成场景，请调用 [method Tools.populateTileMapCells]
static func populateTileMap(map: TileMapLayer, sceneToCopy: PackedScene, numberOfCopies: int, parentOverride: Node = null, groupToAddTo: StringName = &"") -> Dictionary[Vector2i, Node2D]:
	# TODO: FIXME: Handle negative cell coordinates
	# TBD: Add option for range of allowed cell coordinates instead of using the entire TileMap?

	# Validation

	if not sceneToCopy:
		DebugSystem.printWarning("Tools.populateTileMap(): No sceneToCopy", str(map))
		return {}

	var mapRect: Rect2i = map.get_used_rect()

	if not mapRect.has_area():
		DebugSystem.printWarning(str("Tools.populateTileMap(): map has no area: ", mapRect.size), str(map))
		return {}

	var totalCells: int = mapRect.size.x * mapRect.size.y

	if numberOfCopies > totalCells:
		DebugSystem.printWarning(str("Tools.populateTileMap(): numberOfCopies: ", numberOfCopies, " > totalCells: ", totalCells), str(map))
		return {}

	# Spawn

	var parent:  Node2D = parentOverride if parentOverride else map
	var newNode: Node2D
	var coordinates:  Vector2i
	var nodesSpawned: Dictionary[Vector2i, Node2D]

	for count in numberOfCopies:
		newNode = sceneToCopy.instantiate()

		# Find a unoccupied cell
		# Rect size = 1 if 1 cell, so subtract - 1
		# TBD: A more efficient way?

		coordinates = Vector2i(
			randi_range(0, mapRect.size.x - 1),
			randi_range(0, mapRect.size.y - 1))

		# NOTE: No chance of an infinite loop because we checked numberOfCopies <= totalCells
		while(nodesSpawned.get(coordinates)):
			coordinates = Vector2i(
				randi_range(0, mapRect.size.x - 1),
				randi_range(0, mapRect.size.y - 1))

		# Position

		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		if newNode is Entity and newNode.getComponent(TileBasedPositionComponent):
			newNode.components.TileBasedPositionComponent.currentCellCoordinates = coordinates

		# Add
		Tools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

	return nodesSpawned


## 在 [TileMapLayer] 网格上的单元格列表上创建指定场景的实例副本。
## 返回创建的节点的 [Dictionary]，以它们的单元格坐标作为键。
## 提示：调用 [method Tools.findRandomTileMapCells] 以获取随机单元格数组。
## 提示：要在整个地图的随机坐标处以固定数量的副本生成场景，请调用 [method Tools.populateTileMap]
static func populateTileMapCells(map: TileMapLayer, cellCoordinates: Array[Vector2i], sceneToCopy: PackedScene, maximumNumberOfCopies: int, spawnChance: float = 1.0, parentOverride: Node = null, groupToAddTo: StringName = &"") -> Dictionary[Vector2i, Node2D]:
	# Validation

	if not sceneToCopy:
		DebugSystem.printWarning("Tools.populateTileMapCells(): No sceneToCopy", str(map))
		return {}

	if cellCoordinates.is_empty():
		DebugSystem.printWarning("Tools.populateTileMapCells(): No cellCoordinates!", str(map))
		return {}

	if is_zero_approx(spawnChance) or spawnChance < 0:
		DebugSystem.printWarning(str("Tools.populateTileMapCells(): spawnChance <= 0: ", spawnChance), str(map))
		return {}

	# Spawn

	var parent:  Node2D = parentOverride if parentOverride else map
	var newNode: Node2D
	var nodesSpawned: Dictionary[Vector2i, Node2D]

	for coordinates in cellCoordinates:
		# PERFORMANCE: Roll the chance before doing all the other checks and calculations
		if spawnChance < 1.0 and not randf() < spawnChance: continue # TBD: Should this be an integer?

		newNode = sceneToCopy.instantiate()

		# Position

		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		if newNode is Entity and newNode.getComponent(TileBasedPositionComponent):
			newNode.components.TileBasedPositionComponent.currentCellCoordinates = coordinates

		# Add
		Tools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

		if nodesSpawned.size() >= maximumNumberOfCopies: break

	return nodesSpawned

#endregion


#region UI Functions

## 创建 [Control] 的 [StyleBox] 的新副本，以避免影响共享同一 StyleBox 的其他控件，
## 并在指定属性上设置指定颜色。
## @experimental
static func setNewStyleBoxColor(control: Control, color: Color, styleBoxName: StringName = &"fill", propertyName: StringName = &"bg_color") -> StyleBox:
	var styleBox: StyleBox = control.get_theme_stylebox(styleBoxName)
	if not styleBox:
		DebugSystem.printWarning(str("GlobalUI.setStyleBoxColor(): Cannot get StyleBox: ", styleBoxName), control)
		return null

	if styleBox is StyleBoxFlat:
		var newStyleBox: StyleBox = styleBox.duplicate() # 注意：不想更改共享同一 StyleBox 的所有控件的颜色！
		newStyleBox.set(propertyName, color)
		control.add_theme_stylebox_override(styleBoxName, newStyleBox)

	return styleBox


## 从 [Dictionary] 设置 [Label] 的文本。
## 遍历 [Label] 数组，通过移除"Label"后缀（如果有）并使其小写来获取节点名称的前缀，
## 并在 [param dictionary] 中搜索与标签名称前缀匹配的任何 String 键。如果有匹配，则将标签的文本设置为每个键的字典值。
## 示例：`logMessageLabel.text = dictionary["logmessage"]`
## 提示：用于快速填充"检查器"UI，其中文本表示选定对象的多个属性等。
## 注意：字典键必须全部为小写。
static func setLabelsWithDictionary(labels: Array[Label], dictionary: Dictionary[String, Variant], shouldShowPrefix: bool = false, shouldHideEmptyLabels: bool = false) -> void:
	# DESIGN: We don't accept an array of any Control/Node because Labels may be in different containers, and some Labels may not need to be assigned from the Dictionary.
	for label: Label in labels:
		if not label: continue

		var namePrefix: String = label.name.trim_suffix("Label").to_lower()
		var dictionaryValue: Variant = dictionary.get(namePrefix)

		label.text = namePrefix + ":" if shouldShowPrefix else "" # TBD: Space after colon?

		if dictionaryValue:
			label.text += str(dictionaryValue)
			if shouldHideEmptyLabels: label.visible = true # Automatically show non-empty labels in case they were already hidden
		else:
			label.text += ""
			if shouldHideEmptyLabels: label.visible = false


## 在不同的 [Label] 中显示指定 [Object] 的属性值。
## 每个 [Label] 必须具有与 [param object] 中匹配属性完全相同的大小写敏感名称：`isEnabled` 但不是 `IsEnabled` 或 `EnabledLabel` 等。
## 提示：示例：可用于在 UI [Container] 中快速显示 [Resource] 或 [Component] 的数据。
## 返回：名称与 [param object] 属性匹配的 [Label] 数量。
## 对于要附加到 UI [Container] 的脚本，请使用 "PrintPropertiesToLabels.gd"
static func printPropertiesToLabels(object: Object, labels: Array[Label], shouldShowPropertyNames: bool = true, shouldHideNullProperties: bool = true, shouldUnhideAvailableLabels: bool = true) -> int:
	var value: Variant # NOTE: Should not be String so we can explicitly check for `null`
	var matchCount: int = 0

	# Go through all our Labels
	for label in labels:
		# Does the object have a property with a matching name?
		value = object.get(label.name)

		if shouldShowPropertyNames: label.text = label.name + ": "
		else: label.text = ""

		# NOTE: Explicitly check for `null` to avoid cases like "0.0" being treated as a non-existent property.
		if value != null:
			label.text += str(value)
			if shouldUnhideAvailableLabels: label.visible = true
			matchCount += 1
		else:
			label.text += "null" if shouldShowPropertyNames else ""
			if shouldHideNullProperties: label.visible = false

	return matchCount

#endregion


#region Text Functions

## 返回枚举的值及其键作为文本字符串。
## 提示：要仅获取与指定值对应的枚举键，请使用 [method Dictionary.find_key]。
## 警告：对于具有非连续值或从 0 以下开始的枚举，或者如果有多个相同的值，或者如果有 'null' 键，可能无法按预期工作。
static func getEnumText(enumType: Dictionary, value: int) -> String:
	# TBD: Less ambiguous name?
	var key: String

	key = str(enumType.find_key(value)) # TBD: Check for `null`?
	if key.is_empty(): key = "[invalid key/value]"

	return str(value, " (", key, ")")


## 遍历 [String] 并将与 [param substitutions] [Dictionary] 的 [method Dictionary.keys] 匹配的所有文本出现替换为这些键的值。
## 示例：{ "Apple":"Banana", "Cat":"Dog" } 的字典会将 [param sourceString] 中的所有 "Apple" 替换为 "Banana"，所有 "Cat" 替换为 "Dog"。
## 注意：不修改 [param sourceString]，而是返回修改后的字符串。
static func replaceStrings(sourceString: String, substitutions: Dictionary[String, String]) -> String:
	var modifiedString: String = sourceString
	for key: String in substitutions.keys():
		modifiedString = modifiedString.replace(key, substitutions[key])
	return modifiedString

#endregion


#region Maths Functions

## 提示：要"截断"小数位数，请使用 Godot 的 [method @GlobalScope.snappedf] 函数。

## "掷"一个从 1…100（含）的随机整数，如果结果小于或等于指定的 [param chancePercent]，则返回 `true`。
## 即如果概率是 10%，那么掷出 1…10 会成功，但 11…100（90 种可能性）会失败。
func rollChance(chancePercent: int) -> bool:
	return randi_range(1, 100) <= chancePercent


## 如果数字超过或低于任一限制（含），则返回一个数字的副本，该数字环绕到 [param minimum] 或 [param maximum] 值。
## 可用于通过向 [param current] 添加/减去偏移量（如 +1 或 -1）来循环遍历范围。该数字可能是数组索引或 `enum` 状态，或者是精灵位置以 Pac-Man 风格环绕屏幕。
static func wrapInteger(minimum: int, current: int, maximum: int) -> int:
	# TBD: Use Godot's pingpong()?
	if minimum > maximum:
		DebugSystem.printWarning(str("cycleInteger(): minimum ", minimum, " > maximum ", maximum, ", returning current: ", current))
		return current
	elif minimum == maximum: # If there is no difference between the range, just return either.
		return minimum

	# NOTE: Do NOT clamp first! So that an already-offset value may be provided for `current`

	# THANKS: rubenverg@Discord, lololol__@Discord
	return posmod(current - minimum, maximum - minimum + 1) + minimum # +1 to make limits inclusive

#endregion


#region File System Functions

## 如果路径不以 "res://" 或 "user://" 开头，则返回添加了指定 [param prefix] 的指定 [param path] 的副本。
## 如果路径已有前缀，则返回未修改的路径。
## 注意：区分大小写。
static func addPathPrefixIfMissing(path: String, prefix: String = "res://") -> String:
	if  not path.begins_with("res://") \
	and not path.begins_with("user://"):
		return prefix + path
	else:
		return path


## 返回所有子文件夹的列表，并递归搜索 [param initialPath] 处文件夹内的任何更深层子文件夹。
## 重要：[param initialPath] 必须以 `"res://"` 或 `"user://"` 开头
static func findAllSubfolders(initialPath: String = "res://") -> PackedStringArray:
	var subfolders: PackedStringArray
	var dirAccess:  DirAccess = DirAccess.open(initialPath)
	if not dirAccess:
		print("Error: Cannot open DirAccess @ " + initialPath) # NOTE: Don't use DebugSystem.gd logging so this method can be used by the Comedot plugin/addon.
		return []

	# PLAN: Go through each folder in the `subfolders` array,
	# index-wise, not via iterator as the array will be modified during iteration.
	# Get the subfolders of each folder, and append them at the end of the array.
	# This way, all child folders are added to the list, and then their children are added, ensuring a full traversal.

	subfolders.append(initialPath) # Add the initial folder to enumerate the contents of

	var index: int = 0
	var parentPath: String
	var newSubfoldersToAppend: PackedStringArray

	while index < subfolders.size():
		# WORKAROUND: Dummy Godot does not give us the full path in each item returned by DirAccess.get_directories_at()
		# so we have to prefix it manually >:(
		parentPath = subfolders[index] # Get the current folder being enumerated, which is assumed to be prefixed with its full path already.
		newSubfoldersToAppend.clear() # Clear any previous additions
		for newSubfolder in DirAccess.get_directories_at(parentPath):
			newSubfoldersToAppend.append(parentPath + "/" + newSubfolder) # Prefix the parent folder's path to each subfolder's name. grrr
		subfolders.append_array(newSubfoldersToAppend)
		index += 1 # Enumerate the next folder

	return subfolders


## 返回指定路径下文件名中包含 [param filter]（不区分大小写）的所有文件的数组。
## 如果 [param filter] 为空，则返回所有文件。
## 如果 [param folderPath] 不以 "res://" 或 "user://"（区分大小写）开头，则添加 "res://"。
## 注意：在导出项目中的 "res://" 路径上使用时，仅返回在给定文件夹级别实际包含在 PCK 中的文件。
static func getFilesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = Tools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var folder: DirAccess = DirAccess.open(folderPath)
	if folder == null:
		DebugSystem.printWarning("getFilesFromFolder() cannot open " + folderPath)
		return []

	folder.list_dir_begin() # CHECK: Necessary for get_files()?
	var files: PackedStringArray

	for fileName: String in folder.get_files():
		if filter.is_empty() or fileName.containsn(filter):
			files.append(folder.get_current_dir() + "/" + fileName) # CHECK: Use get_current_dir() instead of folderPath?

	folder.list_dir_end() # CHECK: Necessary for get_files()?
	return files


## 返回指定文件夹中导出的资源数组，这些资源的导出文件名中包含 [param filter]（不区分大小写）。
## 如果 [param filter] 为空，则返回所有资源。
## 如果 [param folderPath] 不以 "res://" 或 "user://"（区分大小写）开头，则添加 "res://"。
static func getResourcesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = Tools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var resources: PackedStringArray = ResourceLoader.list_directory(folderPath)
	if resources.is_empty(): return []

	if not folderPath.ends_with("/"): folderPath += "/" # Tack the tail on

	var filteredResources: PackedStringArray
	for resourceName: String in resources:
		if filter.is_empty() or resourceName.containsn(filter):
			filteredResources.append(folderPath + resourceName)

	return filteredResources


## 返回指定对象的路径，在将其扩展名替换为指定字符串之后。
## 可用于快速获取 `.tscn` 场景或 `.tres` 资源的配套 `.gd` 脚本，如果它们共享相同的文件名。
## 如果替换扩展名后的结果文件不存在，则返回空字符串。
static func getPathWithDifferentExtension(sourcePath: String, replacementExtension: String) -> String:
	# var sourcePath: String = object.get_script().resource_path
	if sourcePath.is_empty(): return ""

	var sourceExtension: String = "." + sourcePath.get_extension() # Returns the file extension without the leading period
	var replacementPath: String = sourcePath.replacen(sourceExtension, replacementExtension) # The `N` in `replacen` means case-insensitive

	DebugSystem.printDebug(str("getPathWithDifferentExtension() sourcePath: ", sourcePath, ", replacementPath: ", replacementPath))

	if FileAccess.file_exists(replacementPath): return replacementPath
	else:
		DebugSystem.printDebug(str("replacementPath does not exist: ", replacementPath))
		return ""

#endregion


#region Miscellaneous Functions

static func validateArrayIndex(array: Array, index: int) -> bool:
	return index >= 0 and index < array.size()


## 检查 [Variant] 值是否可被视为"成功"，例如函数的返回值。
## 如果 [param value] 是 [bool]，则按原样返回。
## 如果值是 [Array] 或 [Dictionary]，如果它不为空，则返回 `true`。
## 对于所有其他类型，如果值不是 `null`，则返回 `true`。
## 提示：用于验证 [Payload] 的 [method executeImplementation] 是否成功执行。
static func checkResult(value: Variant) -> bool:
	# 因为 GDScript 没有元组 :')
	if    value is bool: return value
	elif  value is Array or value is Dictionary: return not value.is_empty()
	elif  value != null: return true
	else: return false


## 停止 [Timer] 并发出其 [signal Timer.timeout] 信号。
## 警告：这可能导致错误，特别是当多个对象使用 `await` 等待 Timer 时。
## 返回：计时器停止前的剩余时间。警告：可能不准确！
static func skipTimer(timer: Timer) -> float:
	# 警告：这可能不准确，因为 Timer 在 `stop()` 调用之前仍在运行。
	var leftoverTime: float = timer.time_left
	timer.stop()
	timer.timeout.emit()
	return leftoverTime


## 在 [param options] 数组中搜索 [param value]，如果找到，则返回列表中的下一项。
## 如果 [param value] 是数组的最后一个成员，则返回数组的第一项。
## 如果数组中只有 1 项，则返回相同的值，或者如果未找到 [param value] 则返回 `null`。
## 提示：可用于循环遍历可能的选项列表，例如 [42, 69, 420, 666]
## 警告：如果列表中有 2 个或更多相同的值，循环可能会"卡住"：[a, b, b, c] 将始终只返回第 2 个 `b`
static func cycleThroughList(value: Variant, list: Array[Variant]) -> Variant:
	if not value or list.is_empty(): return null

	var index: int = list.find(value)

	if index >= 0: # -1 means value not found.
		if list.size() == 1: return value
		else: return list[index+1] if index < list.size()-1 else list[0] # Wrap around if at the end of the array.
	else: return null

#endregion
