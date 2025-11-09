## 组合框架的核心。表示游戏角色或对象的独特行为或属性的节点。
## 由 Component 子节点组成的父节点是一个 [Entity]。Entity 是"脚手架"，而 Components 执行实际工作（游戏逻辑）。
## Components 可以在不同类型的实体中重复使用，例如用于玩家角色和怪物的 [HealthComponent]。
## Components 可以直接修改父实体或与其他组件交互，
## 例如 [DamageComponent] 与另一个 Entity 的 [DamageReceivingComponent] 通信，然后修改 [HealthComponent]。

#@tool # Not useful because it's not inherited :(
@icon("res://Assets/Icons/Component.svg")

@abstract class_name Component
extends Node


#region Advanced Parameters

## 如果父节点不是 [Entity]，是否应该检查所有祖父/曾祖父节点，直到在场景树层次结构中找到 [Entity]？
## 被 [member allowNonEntityParent] 覆盖
## 警告：高级选项！可能导致错误或降低性能。仅在您知道自己在做什么时使用！
## @experimental
@export var shouldCheckGrandparentsForEntity: bool = false

## 允许此组件添加到不是 [Entity] 的节点？
## 覆盖 [member shouldCheckGrandparentsForEntity]
## 警告：高级选项！可能导致错误或降低性能。仅在您知道自己在做什么时使用，或用于将"载荷"组件添加到 [InjectorComponent] 等情况。
## @experimental
@export var allowNonEntityParent: bool = false

#endregion


#region Core Properties
# TBD: @export_storage?

var parentEntity: Entity:
	set(newValue):
		if newValue != parentEntity:
			if debugMode: printChange("parentEntity", parentEntity, newValue)
			parentEntity = newValue
			if parentEntity and parentEntity != self.get_parent(): # Don't verify if `null`, because during NOTIFICATION_UNPARENTED get_parent() will still return the about-to-unparent Entity.
				printWarning(str("parentEntity set to: ", parentEntity, ", not the actual parent: ", self.get_parent()))
			# NOTE: Entity-dependent flags & properties should be copied/cleared in the related life cycle methods,
			# to be in proper order with other operations such as signals etc.

## [parentEntity] 的 [member Entity.components] 中其他 [Component] 的 [Dictionary]。
## 通过快捷方式 `coComponents.ComponentClassName` 访问，或
## 提示：使用 `coComponents.get(&"ComponentClassName")` 以避免在可选组件缺失时崩溃，并返回 `null`
## 注意：不会查找继承指定类型的子类；请改用 [method Entity.findFirstComponentSubclass]。
var coComponents: Dictionary[StringName, Component]

#endregion


#region Signals

## 在 [constant Node.NOTIFICATION_UNPARENTED] 时发出。
## 可以由子类连接以执行特定于每个组件的清理。
## 注意：此时 [member parentEntity] 仍被分配，在此信号发出后设置为 `null`。
signal willRemoveFromEntity

#endregion


#region Validation

## 注意：仅在此脚本顶部指定了 `@tool` 时使用。
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not is_instance_of(self.get_parent(), Entity):
		warnings.append("Component nodes should be added to a parent which inherits from the Entity class.")

	if not checkRequiredComponents():
		warnings.append("This component is missing a required co-component. Check the getRequiredComponents() method.")

	return warnings


## 返回：此组件依赖的其他组件类型列表。
## 必须由子类覆盖。
func getRequiredComponents() -> Array[Script]:
	# 这需要是一个方法，因为属性无法被覆盖 :')
	return []


func checkRequiredComponents() -> bool:
	var requiredComponentTypes: Array[Script] = self.getRequiredComponents()
	if requiredComponentTypes.is_empty(): return true # If there are no requirements, we have everything we need :)

	if not parentEntity or parentEntity.components.keys().is_empty(): return false # If there are no other components, we don't have any of our requirements :()

	var haveAllRequirements: bool = true # Start `true` then make it `false` if there is any missing requirement.

	for requirement in requiredComponentTypes:
		# DEBUG: printDebug(str(requirement))
		if not parentEntity.components.keys().has(requirement.get_global_name()): # Convert `Script` types to their `StringName` keys
			printWarning(str("Missing requirement: ", requirement.get_global_name(), " in ", parentEntity.logName))
			haveAllRequirements = false

	return haveAllRequirements

#endregion


#region Life Cycle
# NOTIFICATION_PARENTED → _enter_tree() → _ready()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:   validateParent()	# Received when a node is set as the child of another node,  not necessarily when the node enters the SceneTree.
		NOTIFICATION_UNPARENTED: unregisterEntity() # Received when a parent calls remove_child() on a child node, not necessarily when the node exit the SceneTree.
		NOTIFICATION_PREDELETE:  if isLoggingEnabled: printLog("[color=brown]􀆄 PreDelete") # NOTE: Cannot print [parentEntity] here because it will always be `null` (?)


## 当组件收到 [constant NOTIFICATION_PARENTED] 时由 [method _notification] 调用，
## 即节点被添加为任何父节点的子节点时。注意：这并不意味着节点已进入 SceneTree（尚未）。
## 如果父节点是 [Entity]，则此组件将注册到该 Entity，
## 否则如果 [member shouldCheckGrandparentsForEntity] 为真，则将搜索所有祖父节点，直到找到 Entity。
func validateParent() -> void:
	# 初始化顺序：1：这似乎在其他方法之前被调用，通过通知，至少在创建新实例时（例如由 GunComponent）

	var newParent: Node = self.get_parent()
	if debugMode: printDebug(str("validateParent(): ", newParent))

	# If the parent node is not an Entity, print a warning if needed
	if not is_instance_of(newParent, Entity):
		var message: String = str("validateParent(): Parent node is not an Entity: ", newParent, " ／ This may prevent sibling components from finding this component.")
		if self.allowNonEntityParent:
			printLog(message + " allowNonEntityParent: true")
		else: printWarning(message)

	if not parentEntity: # Are we a new Component [or] not owned by an Entity?

		if newParent is Entity: # If our parent is an Entity, all's well and good in the world.
			self.registerEntity(newParent)

		# If our immediate parent node is not an Entity, should we search up the scene tree hierarchy for an Entity to adopt this Component?
		elif shouldCheckGrandparentsForEntity and not allowNonEntityParent:
			var grandparentEntity: Entity = self.findParentEntity(true)
			if grandparentEntity:
				self.registerEntity(grandparentEntity)

	else: # Do we already have an Entity?

		if parentEntity == newParent:
			# Warn because why are this initialization method being called again?
			printWarning(str("validateParent() called again for parentEntity that is already set: ", parentEntity))
		else: # Are we already owned by an Entity Node that is NOT the new parent?
			# CHECK: This situation should never happen, so treat it as an Error, right?
			printError(str("parentEntity already set to a different parent: ", parentEntity))


## 当节点首次进入场景树时调用。
func _enter_tree() -> void:
	# 初始化顺序：2：在 Entity._enter_tree() 之后，在 Entity.childEnteredTree() 之前

	self.add_to_group(GlobalSystem.Groups.components, true) # persistent

	# 查找此 Component 属于哪个 Entity，如果尚未设置。
	if not self.parentEntity: registerEntity(self.findParentEntity())

	# 未使用：update_configuration_warnings() # 仅在 @tool 脚本时有用

	if parentEntity:
		# 注意：设计：如果实体的日志标志为真，默认采用它们是有意义的，
		# 但如果实体的日志关闭而特定组件的日志打开，则应尊重组件的标志。
		# 检查：这些标志是否仅在第一次 _enter_tree() 时设置一次，还是在设置新的 `parentEntity` 时也设置？
		self.isLoggingEnabled = self.isLoggingEnabled or parentEntity.isLoggingEnabled
		self.debugMode		  = self.debugMode or parentEntity.debugMode
		printLog("􀈅 [b]_enter_tree() → " + parentEntity.logName + "[/b]", self.logFullName)
		self.checkRequiredComponents()
	else:
		self.coComponents = {} # 清除我们对任何兄弟组件的先前记忆
		if not allowNonEntityParent: printWarning("􀈅 [b]_enter_tree() with no parentEntity![/b]")


## 向上搜索场景树，查找类型为 [Entity] 的父节点或祖父节点并返回它。
## 即检查每个父节点的父节点，直到找到 [Entity]。
func findParentEntity(checkGrandparents: bool = self.shouldCheckGrandparentsForEntity) -> Entity:
	var parentOrGrandparent: Node = self.get_parent()

	# 如果父节点为 null 或不是 Entity，则检查祖父节点（父节点的父节点）并继续向上搜索树。
	if checkGrandparents:
		while not (parentOrGrandparent is Entity) and not (parentOrGrandparent == null):
			if debugMode: printDebug(str("findParentEntity() checking parent of non-Entity node: ", parentOrGrandparent))
			parentOrGrandparent = parentOrGrandparent.get_parent()

	if parentOrGrandparent is Entity:
		if debugMode: printDebug(str("findParentEntity() result: ", parentOrGrandparent))
		return parentOrGrandparent
	elif not allowNonEntityParent:
		printWarning(str("findParentEntity() found no Entity! checkGrandparents: ", checkGrandparents))

	return null


func registerEntity(newParentEntity: Entity) -> void:
	if debugMode: printDebug(str("registerEntity(): ", newParentEntity))
	if not newParentEntity: return
	self.parentEntity = newParentEntity
	self.parentEntity.registerComponent(self) # NOTE: DESIGN: The COMPONENT must call this method. See Entity.childEnteredTree() notes for explanation.
	self.coComponents = parentEntity.components


## 从父 [Entity] 中移除此组件，除非指定，否则释放（删除）该组件。
## 仅移除但未释放的组件可以重新添加到任何实体，
func removeFromEntity(shouldFree: bool = true) -> void:
	if parentEntity and parentEntity == self.get_parent():
		parentEntity.remove_child(self)
	else:
		# 待定：显示警告，或者如果组件已被移除，这是否多余？
		pass # 调试：printWarning(str("Cannot removeFromEntity: ", parentEntity))
	if shouldFree: self.queue_free()


## 如果父实体同意，则在自身上调用 [method queue_free()]。如果已移除，返回 `true`。
## 可以在子类中覆盖以检查其他条件和逻辑。
func requestDeletion() -> bool:
	# 待定：询问父实体是否同意？
	self.queue_free()
	return true


## 如果父 [Entity] 同意 [method Entity.requestDeletion] 或没有 [member parentEntity]，则返回 `true`。
func requestDeletionOfParentEntity() -> bool:
	if parentEntity:
		if debugMode: printDebug(str("requestDeletionOfParentEntity(): ", parentEntity.logName))
		if parentEntity.requestDeletion():
			return true
		else:
			if debugMode: printDebug(str("requestDeletionOfParentEntity(): requestDeletion() refused by ", parentEntity.logName))
			return false
	else:
		if debugMode: printWarning("requestDeletionOfParentEntity(): parentEntity already null!")
		return true # 注意：设计：如果代码调用此函数，则它希望 Entity 消失，所以如果它已经消失，我们应该返回 `true` :)


## 当组件收到 [constant NOTIFICATION_UNPARENTED] 时由 [method _notification] 调用，
## 即父节点在组件节点上调用 [method Node.remove_child] 时。
## 注意：这并不意味着节点已退出 SceneTree（尚未）。
func unregisterEntity() -> void:
	# 反初始化顺序：2：在 Entity._exit_tree() 之后
	# 检查：此时是否仍有父引用可用？
	if debugMode: printDebug(str("unregisterEntity() ", get_parent()))
	if parentEntity:
		willRemoveFromEntity.emit()
		self.coComponents = {} # 检查：性能：`= {}` 更快还是 .clear()？
		parentEntity.unregisterComponent(self)
		self.parentEntity = null # 待定：使用 .set_deferred()？
		if isLoggingEnabled: printLog("[color=brown]􀆄 Unparented")


## 注意：即使 Entity 从场景中移除（连同其所有子节点）时也会调用此方法，
## 因此这不一定意味着此 Component 已从 ENTITY 中移除。
func _exit_tree() -> void:
	# 反初始化顺序：1：在 Entity.childExitingTree()、Entity._exit_tree() 之前
	# 注意：避免：`parentEntity` 不能在这里设为 `null`！也不能设置 `coComponents`！
	# 因为如果 Entity 本身 _exit_tree()，Component 可能在其仍是 Entity 的子节点时 _exit_tree()
	var entityName: String = parentEntity.logName if parentEntity else "null" # 检查 parentEntity，因为组件可能在没有作为 Entity 子节点的情况下被释放
	printLog("[color=brown]􀈃 _exit_tree() parentEntity: " + entityName, self.logFullName)

#endregion


#region Family
# Join the serpent king!

## 从 [member coComponents] [Dictionary] 返回一个兄弟 [Component]，
## 在将 [param type] [method Script.get_global_name] 转换为 [StringName] 之后。
## 如果 [param includeSubclasses] 为 `true`，则调用 [method Entity.findFirstComponentSubclass] 以查找扩展/继承指定类型的第一个 [Component]。
## 警告：与直接访问 [member coComponents] [Dictionary] 相比性能较慢！仅在需要警告而不是崩溃时使用此方法，以防组件缺失。
func findCoComponent(type: Script, includeSubclasses: bool = true) -> Component:
	# 待定：[Script] 是参数的正确类型吗？
	var coComponent: Component = coComponents.get(type.get_global_name())

	if not coComponent:

		if includeSubclasses:
			coComponent = parentEntity.findFirstComponentSubclass(type)
			printDebug(str("Searching for subclass of ", type, " in parentEntity: ", parentEntity, " — Found: ", coComponent))

		if not coComponent: # 我们仍然没有找到任何匹配吗？:(
			printWarning(str("Missing co-component: ", type.get_global_name(), " in parent Entity: ", parentEntity.logName))

	return coComponent


## 要求父 [Entity] 移除此组件相同类的所有其他组件。
## 当应该只有一个特定类的组件时（例如 [FactionComponent]）替换组件时很有用。
## 返回：移除的组件数量。
func removeSiblingComponentsOfSameType() -> int:
	var removalCount: int = 0

	for sibling: Component in parentEntity.get_children(false): # 不包括子子节点
		# 是我们自己吗？
		if sibling == self: continue

		if is_instance_of(sibling, self.get_script().get_global_name()):
			sibling.requestDeletion()
			removalCount += 1

	return removalCount

#endregion


#region Miscellaneous Interface

## 如果可用，将 [member isEnabled] 标志设置为其相反值，或如果指定则设置为 [param overrideIsEnabled]。
## 还可以根据结果 `isEnabled` 状态或如果没有 `isEnabled` 标志则根据 [param overrideIsEnabled] 选择性地暂停/取消暂停组件。
## 警告：对 [member isEnabled] 的更改可能不会被接受，基于子类特定的属性设置器等。
## 警告：取消暂停总是将 [member Node.process_mode] 设置为 [constant Node.PROCESS_MODE_INHERIT]，这可能不是暂停之前的先前/默认设置。
## 返回：如果有 `isEnabled` 标志，则返回结果 [member isEnabled] 状态，否则如果 [member Node.process_mode] 不是 [constant Node.PROCESS_MODE_DISABLED] 则返回 `true`。
func toggleEnabled(overrideIsEnabled: Variant = null, togglePause: bool = false) -> bool:
	# 待定：检查：暂停/取消暂停并保存先前值的更好方法？
	# 警告：如果组件之前的状态不是"INHERIT"，则不会恢复

	if debugMode: printDebug(str("toggleEnabled(): isEnabled? ", (self.isEnabled if &"isEnabled" in self else "null"), ", override: ", overrideIsEnabled, ", togglePause: ", togglePause))

	if &"isEnabled" in self: # CHECK: Should it be a StringName?
		if overrideIsEnabled != null and overrideIsEnabled is bool:
			self.isEnabled = overrideIsEnabled
		else:
			self.isEnabled = not self.isEnabled

		if togglePause:
			# NOTE: Pause/unpause based on the final `isEnabled` state
			self.process_mode = PROCESS_MODE_INHERIT if self.isEnabled else PROCESS_MODE_DISABLED

		return self.isEnabled

	elif togglePause: # If there is no `isEnabled` property
		if overrideIsEnabled != null and overrideIsEnabled is bool:
			self.process_mode = PROCESS_MODE_INHERIT if overrideIsEnabled == true else PROCESS_MODE_DISABLED
		else:
			if self.process_mode != PROCESS_MODE_DISABLED: self.process_mode = PROCESS_MODE_DISABLED
			else: self.process_mode = PROCESS_MODE_INHERIT

	return self.process_mode != PROCESS_MODE_DISABLED # If there is no `isEnabled` just return `true` for any state except disabled

#endregion


#region Static Methods

## 尝试将任何 Node 转换为 Component，因为 `Component.gd` 脚本可以附加到任何 Node。
## 如果 [param node] 不是组件，但节点的父/祖父是 Entity，如果 [param findInParentEntity] 为真，则搜索 Entity 以查找匹配的 [param componentType]。
## @experimental
static func castOrFindComponent(node: Node, componentType: GDScript, findInParentEntity: bool = true) -> Component:
	# 首先，尝试转换节点本身。
	var component: Component = node.get_node(^".") as Component # 技巧：找到更好的转换自身的方法？

	if not component:
		DebugSystem.printDebug(str("Cannot cast ", node, " as ", componentType.get_global_name()), "Component.castOrFindComponent()")

		# Try to see if the node's grand/parent is an Entity
		if findInParentEntity:
			var nodeParent: Entity = Tools.findFirstParentOfType(node, Entity)
			if nodeParent:
				component = nodeParent.components.get(componentType.get_global_name())
				if not component:
					DebugSystem.printDebug(str("node parent ", nodeParent, " has no ", componentType.get_global_name()), "Component.castOrFindComponent()")
					return null
			else:
				DebugSystem.printDebug(str("node parent is not an Entity: ", nodeParent), "Component.castOrFindComponent()")
				return null

	return component

#endregion


#region Logging

@export_group("Debugging")

## 为此组件启用更详细的调试信息，例如详细日志消息、视觉指示器、[member Debug.watchList] 实时属性标签或图表窗口等。
## 注意：子类可能会添加自己的信息或可能不遵守此标志。
## 如果最初为 `false`，则默认为实体的 [member Entity.debugMode]。
## 注意：尽管 [method printDebug] 也检查此标志，但在调用 `printDebug()` 等函数（如 `str()`）之前应检查此标志，因为这可能会降低性能。
@export var debugMode:		bool

## 如果为 `true`，所有对 [method Component.printDebug] 的调用都会转发到 [method Debug.printTrace]，其中包括最近函数调用列表和高亮颜色。
## 这可能有助于快速跟踪特定组件中的特定问题。
## 注意：抑制 `debugMode = false`，即 [method printDebug] 总是被打印。
@export var debugModeTrace:	bool


## 如果最初为 `false`，则默认为实体的 [member Entity.isLoggingEnabled]。
## 注意：不影响警告和错误！
var isLoggingEnabled:		bool

var logName: String: # 注意：这是一个动态属性，因为直接赋值会在设置 `name` 之前设置值。
	get: return "􀥭 " + self.name

## 更详细的名称，包括节点名称、实例和脚本的 `class_name`。
var logFullName: String:
	get: return str("􀥭 ", self, ":", self.get_script().get_global_name())

## [member Component.logName] + [member Entity.logName]
var logNameWithEntity: String:
	get: return self.logName + ((" " + parentEntity.logName) if parentEntity else "")

## [member Component.logFullName] + [member Entity.logFullName]
var logFullNameWithEntity: String:
	get: return self.logFullName + ((" " + parentEntity.logFullName) if parentEntity else "")

var randomDebugColor: Color = Tools.getRandomQuantizedColor() ## Used by [method emitDebugBubble] etc. to distinguish different components from each other.

func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	DebugSystem.printLog(message, object, "lightBlue", "cyan")


## 受 [member debugMode] 影响，但不受 [member isLoggingEnabled] 影响。
## 注意：如果 [member debugModeTrace] 打开，则即使 debugMode 关闭，也总是调用 [method Debug.printTrace]。
## 提示：尽管此方法检查 [member debugMode]，但在调用 [method printDebug] 之前检查该标志，以避免不必要的函数调用（如 `str()`）并提高性能。
func printDebug(message: String = "") -> void:
	# 设计：此方法不遵守 isLoggingEnabled，因为我们经常需要禁用常见的"簿记"日志（如创建/销毁），但在开发新功能时需要调试信息。
	if debugModeTrace: DebugSystem.printTrace(message.split(", "), self.logNameWithEntity, 3) # 从调用堆栈更远的地方开始以跳过此方法 # 待定：按 ", " 拆分为数组以用于常见用例？
	elif debugMode: DebugSystem.printDebug(message, logName, "cyan")


## 调用 [method Debug.printWarning]
## 注意：忽略 [member isLoggingEnabled]
func printWarning(message: String = "") -> void:
	DebugSystem.printWarning(message, logFullName, "cyan")


## 调用 [method Debug.printError]
## 注意：忽略 [member isLoggingEnabled]
func printError(message: String = "") -> void:
	DebugSystem.printError(message, logFullName, "cyan")


## 以高亮颜色打印变量数组，以及在调用 [method Debug.printTrace] 之前最近函数及其文件名的简短"堆栈跟踪"。
## 提示：有助于快速/临时调试当前关注的问题。
## 受 [member debugMode] 影响，仅在调试构建中打印。
func printTrace(...values: Array[Variant]) -> void:
	DebugSystem.printTrace(values, self.logNameWithEntity, 3) # 从调用堆栈更远的地方开始以跳过此方法


## 如果有更改且 [member debugMode]，则记录显示变量先前值和新值的条目。
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsDebug: bool = true) -> void:
	if debugMode and previousValue != newValue:
		var string: String = str(variableName, ": ", previousValue, " → ", newValue)
		if not logAsDebug: printLog("[color=gray]" + string)
		else: printDebug(string)


#endregion
