## 将父 Entity 的位置设置为关联 [TileMapLayer] 中图块的位置。
## 注意：不接收玩家控制输入，也不执行路径查找或任何其他验证逻辑，
## 除了检查图块地图边界和图块碰撞。
## 提示：要提供玩家输入，请使用 [TileBasedControlComponent]。
## 要求：[TileMapLayerWithCellData] 或单独的 [TileMapLayer] + [TileMapCellData]

class_name TileBasedPositionComponent
extends Component

# 计划：
# * 存储整数坐标以记住实体所在的图块。
# * 每帧，
# 	如果实体没有移动到另一个图块，则将实体对齐到当前图块的位置，以防 TileMap 正在移动。
# 	如果实体正在移动到另一个图块，则将实体的位置插值到新图块。

# 待办：在 _process() 中设置沿途每个图块的占用


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame))


@export_group("Tile Map")

@export var tileMap: TileMapLayer:
	set(newValue):
		if newValue != tileMap:
			printChange("tileMap", tileMap, newValue)

			# If we have a TileMap and are about to leave it, mark our cell as no longer occupied.
			if tileMap and not newValue: vacateCurrentCell()

			tileMap = newValue
			# NOTE: TBD: Don't need validateTileMap() here

			if not self.tileMapData: # Try to get the TileMapCellData if we don't already have it
				if tileMap is TileMapLayerWithCellData: self.tileMapData = tileMap.cellData
				else: printDebug(str("tileMapData not set & tileMap missing TileMapCellData: ", tileMap))
			# NOTE: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

@export var tileMapData: TileMapCellData:
	set(newValue):
		if tileMapData != newValue:
			printChange("tileMapData", tileMapData, newValue)

			# If we have a TileMap and are about to leave it, mark our cell as no longer occupied.
			if tileMapData and not newValue: vacateCurrentCell()

			tileMapData = newValue
			if tileMapData: validateTileMap()
			# NOTE: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

## 如果为 `true` 且 [member tileMap] 为 `null`，则将搜索当前场景并使用第一个 [TileMapLayerWithCellData]（如果有）。
## 警告：在 TileMap 之间动态移动或设置新实体时会导致错误。
## @experimental
@export var shouldSearchForTileMap: bool = false


@export_group("Initial Position")

@export var setInitialCoordinatesFromEntityPosition: bool = false
@export var initialDestinationCoordinates: Vector2i

## 如果为 `false`，实体将立即定位到初始目标，否则如果 `shouldMoveInstantly` 为 false，则可以从执行此组件之前的位置进行动画。
@export var shouldSnapToInitialDestination: bool = true


@export_group("Movement")

## 在图块之间移动的速度。如果 [member shouldMoveInstantly] 为真则忽略。
## 警告：如果这比 [member tileMap] 的移动慢，则组件永远无法赶上目标图块的位置。
@export_range(10, 1000, 1) var speed: float = 200

@export var shouldMoveInstantly: bool = false

@export var shouldClampToBounds: bool = true ## 将实体保持在 [member tileMap] 的"已绘制"单元格区域内？

## 单元格是否应由父 Entity 标记为 [constant Global.TileMapCustomData.isOccupied]？
## 设置为 `false` 以禁用占用；对于仅视觉的实体（如鼠标光标和其他 UI/效果）很有用。
@export var shouldOccupyCell: bool = true

## 如果为 `true`，则每帧调用 [method snapEntityPositionToTile] 以将 Entity 锁定到 [TileMapLayer] 网格。
## 警告：性能：仅在 Entity 或 [TileMapLayer] 可能在运行时被其他脚本或效果移动时启用，以避免每帧不必要的处理。
@export var shouldSnapPositionEveryFrame: bool = false:
	set(newValue):
		if newValue != shouldSnapPositionEveryFrame:
			shouldSnapPositionEveryFrame = newValue
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame)) # 性能：仅在需要时每帧更新

## 在移动时在目标图块处临时显示的 [Sprite2D] 或任何其他 [Node2D]，例如方形光标等。
## 注意：组件场景中提供了一个示例光标，但默认未启用。启用 `Editable Children` 以使用它。
@export var visualIndicator: Node2D

#endregion


#region State

# TODO: TBD: @export_storage

var currentCellCoordinates: Vector2i:
	set(newValue):
		if newValue != currentCellCoordinates:
			printChange("currentCellCoordinates", currentCellCoordinates, newValue)
			currentCellCoordinates = newValue

var destinationCellCoordinates: Vector2i:
	set(newValue):
		if newValue != destinationCellCoordinates:
			printChange("destinationCellCoordinates", destinationCellCoordinates, newValue)
			destinationCellCoordinates = newValue

# var destinationTileGlobalPosition: Vector2i # NOTE: UNUSED: Not cached because the [TIleMapLayer] may move between frames.

var inputVector: Vector2i:
	set(newValue):
		if newValue != inputVector:
			if debugMode: DebugSystem.printChange("inputVector", inputVector, newValue)
			# previousInputVector = inputVector # NOTE: This causes "flicker" between 0 and the other value, when resetting the `inputVector`, so just set it manually
			inputVector = newValue

var previousInputVector: Vector2i

var isMovingToNewCell: bool = false:
	set(newValue):
		if newValue != isMovingToNewCell:
			isMovingToNewCell = newValue
			updateIndicator()
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame)) # PERFORMANCE: Update per-frame only when needed

#endregion


#region Signals
signal willStartMovingToNewCell(newDestination: Vector2i)
signal didArriveAtNewCell(newDestination: Vector2i)

signal willSetNewMap(previousMap: TileMapLayer, currentCoordinates: Vector2i, newMap: TileMapLayer, newCoordinates: Vector2i)
signal didSetNewMap(previousMap:  TileMapLayer, currentCoordinates: Vector2i, newMap: TileMapLayer, newCoordinates: Vector2i)
#endregion


#region Life Cycle

func _ready() -> void:
	validateTileMap()

	if debugMode:
		self.willStartMovingToNewCell.connect(self.onWillStartMovingToNewCell)
		self.didArriveAtNewCell.connect(self.onDidArriveAtNewCell)

	# The tileMap may be set later, if this component was loaded dynamically at runtime, or initialized by another script.
	if tileMap: applyInitialCoordinates()

	updateIndicator() # Fix the visually-annoying initial snap from the default position
	self.willRemoveFromEntity.connect(self.onWillRemoveFromEntity)


func onWillRemoveFromEntity() -> void:
	# Set our cell as vacant before this component or entity is removed.
	vacateCurrentCell()

#endregion


#region Validation

## 验证 [member tileMap] 和 [member tileMapData]。
func validateTileMap(searchForTileMap: bool = self.shouldSearchForTileMap) -> bool:
	# 待办：如果缺失，尝试使用在当前场景中找到的第一个 [TileMapLayerWithCellData]（如果有）？

	if not tileMap:
		if searchForTileMap:
			if debugMode: printDebug("tileMap not specified! Searching for first TileMapLayerWithCellData or TileMapLayer in current scene…")
			self.tileMap = Tools.findFirstChildOfAnyTypes(get_tree().current_scene, [TileMapLayerWithCellData, TileMapLayer], false) # not returnParentIfNoMatches # 警告：在 TileMap 之间动态移动或设置新实体时会导致错误。

		# 仅在 debugMode 中警告，以防 tileMapData 将由不同的脚本提供。
		if debugMode and not tileMap: printWarning("Missing TileMapLayerWithCellData or TileMapLayer")

	# 如果不存在，设置 TileMapCellData

	if not tileMapData:
		if tileMap and tileMap is TileMapLayerWithCellData:
			self.tileMapData = tileMap.cellData

		if not tileMapData:
			printWarning(str("Missing tileMapData for tileMap: ", tileMap))

	return tileMap and tileMapData # 仅当两个对象都有效时验证通过


## 确保指定坐标在 [TileMapLayer] 的边界内
## 并调用 [method checkCellVacancy]。
## 可以由子类覆盖以执行其他检查。
## 注意：子类必须调用 super 以执行通用验证。
func validateCoordinates(coordinates: Vector2i) -> bool:
	var isValidBounds: bool = Tools.checkTileMapCoordinates(tileMap, coordinates)
	var isTileVacant:  bool = self.checkCellVacancy(coordinates)

	if debugMode: printDebug(str("@", coordinates, ": checkTileMapCoordinates(): ", isValidBounds, ", checkCellVacancy(): ", isTileVacant))

	return isValidBounds and isTileVacant


## 检查是否可以移动到该图块。
## 可以由子类覆盖以执行不同的检查，
## 例如测试图块上的自定义数据，例如 [constant Global.TileMapCustomData.isWalkable]，
## 和单元格上的自定义数据，例如 [constant Global.TileMapCustomData.isOccupied]，
## 或执行更严格的物理碰撞检测。
func checkCellVacancy(coordinates: Vector2i) -> bool:
	# 未使用：Tools.checkTileCollision(tileMap, parentEntity.body, coordinates) # 全局方法的当前实现总是返回 `true`。
	if tileMapData:
		return Tools.checkTileAndCellVacancy(tileMap, tileMapData, coordinates, self.parentEntity) # 忽略我们自己的实体，以防万一 :')
	else:
		return Tools.checkTileVacancy(tileMap, coordinates)

#endregion


#endregion Positioning

func applyInitialCoordinates() -> void:
	# Get the entity's starting coordinates
	updateCurrentTileCoordinates()

	if setInitialCoordinatesFromEntityPosition:
		initialDestinationCoordinates = currentCellCoordinates

	# Even if we `setInitialCoordinatesFromEntityPosition`, snap the entity to the center of the cell

	# NOTE: Directly setting `destinationCellCoordinates = initialDestinationCoordinates` beforehand prevents the movement
	# because the functions check for a change between coordinates.

	if shouldSnapToInitialDestination:
		snapEntityPositionToTile(initialDestinationCoordinates)
	else:
		setDestinationCellCoordinates(initialDestinationCoordinates)


## 设置与父 Entity 的 [member Node2D.global_position] 对应的图块坐标
## 并设置单元格的占用。
func updateCurrentTileCoordinates() -> Vector2i:
	self.currentCellCoordinates = tileMap.local_to_map(tileMap.to_local(parentEntity.global_position))
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, true, parentEntity)
	return currentCellCoordinates


## 立即将实体的位置设置为图块的位置。
## 注意：不验证坐标或检查单元格的空闲等。
## 提示：对于 UI 元素（如光标等）可能很有用。
## 如果省略 [param destinationOverride]，则使用 [member currentCellCoordinates]。
func snapEntityPositionToTile(tileCoordinates: Vector2i = self.currentCellCoordinates) -> void:
	if not isEnabled: return

	var tileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, tileCoordinates)

	if parentEntity.global_position != tileGlobalPosition:
		parentEntity.global_position = tileGlobalPosition

	self.currentCellCoordinates = tileCoordinates

#endregion


#region Control

## 此方法必须在控制组件收到玩家输入时调用。
## 示例：`inputVector = Vector2i(Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown))`
func processMovementInput(inputVectorOverride: Vector2i = self.inputVector) -> void:
	# 待办：检查 TileMap 边界。
	# 如果已经在移动到新图块，则不接受输入。
	if (not isEnabled) or self.isMovingToNewCell: return
	setDestinationCellCoordinates(self.currentCellCoordinates + inputVectorOverride)


## 返回：如果新目标坐标在 TileMap 边界内无效，则返回 `false`。
func setDestinationCellCoordinates(newDestinationTileCoordinates: Vector2i) -> bool:

	# 新目标是否与当前目标相同？那么没有什么需要改变的。
	if newDestinationTileCoordinates == self.destinationCellCoordinates: return true

	# 新目标是否与当前图块相同？即先前的移动是否被取消？
	if newDestinationTileCoordinates == self.currentCellCoordinates:
		cancelDestination()
		return true # 注意：返回 true，因为到达指定坐标应被视为成功，即使已经在那里。:)

	# 验证新目标？

	if not validateCoordinates(newDestinationTileCoordinates):
		return false

	# 移动你的身体 ♪

	willStartMovingToNewCell.emit(newDestinationTileCoordinates)
	self.destinationCellCoordinates = newDestinationTileCoordinates
	self.isMovingToNewCell = true

	# 清空当前（即将成为先前的）图块
	# 注意：即使不是 `shouldOccupyCell`，也总是清空先前的单元格，以防在运行时从 true 切换为 false。
	if tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, false, null)

	# 待办：待定：每帧也占用沿途的每个单元格？
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, newDestinationTileCoordinates, true, parentEntity)

	# 我们应该传送吗？
	if shouldMoveInstantly: snapEntityPositionToTile(destinationCellCoordinates)

	return true


## 取消当前移动，并在需要时清空先前的 [member destinationCellCoordinates]。
func cancelDestination(snapToCurrentCell: bool = true) -> void:
	# 首先，清空先前目标的占用，以防我们占用了它
	# 注意：无论 `shouldOccupyCell` 如何，都清空
	if tileMapData and Tools.getCellOccupant(tileMapData, self.destinationCellCoordinates) == parentEntity:
		Tools.setCellOccupancy(tileMapData, self.destinationCellCoordinates, false, null)

	# 我们是否正在前往不同的目标图块？
	if isMovingToNewCell and snapToCurrentCell:
		# 然后对齐回当前图块坐标。
		# 待办：选项以动画返回？
		self.snapEntityPositionToTile(self.currentCellCoordinates)

	self.destinationCellCoordinates = self.currentCellCoordinates
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity) # 重新占用当前单元格
	self.isMovingToNewCell = false


func vacateCurrentCell() -> void:
	if tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, false, null)


## 使用新的 [TileMapLayer] 并保留屏幕上的当前像素位置，但可能在新地图的网格上获得不同的单元格坐标。
## 注意：验证新单元格坐标在新地图中是否未被占用，但不验证边界；当前像素位置可能在新地图的网格之外。
## 返回：旧地图上的先前单元格坐标与新地图上的更新单元格坐标之间的差异。
func setMapAndKeepPosition(newMap: TileMapLayer, useNewData: bool = true) -> Vector2i:
	if not newMap or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepPosition(): newMap == current map or null: ", newMap))
		return Vector2i.ZERO # Nothing to do if nowhere to move!

	var previousCoordinates: Vector2i = self.currentCellCoordinates
	var previousDestination: Vector2i = self.destinationCellCoordinates
	var newCoordinates:		 Vector2i = Tools.convertCoordinatesBetweenTileMaps(self.tileMap, self.currentCellCoordinates, newMap)
	var isNewCellVacant:	 bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = Tools.checkTileAndCellVacancy(newMap, newMap.cellData, newCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, newCoordinates)

	if debugMode: printDebug(str("setMapAndKeepPosition(): ", self.tileMap, " @", previousCoordinates, ", pixel global position: ", parentEntity.global_position, " → ", newMap, " @", newCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, newCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		willSetNewMap.emit(self.tileMap, previousCoordinates, newMap, newCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelDestination(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCellCoordinates`
			Tools.setCellOccupancy(self.tileMapData, previousCoordinates, false, null) # isOccupied, occupant

		# NOTE: Do not replace our own data until the movement has been validated and the previous cell has been vacated.
		if useNewData and newMap is TileMapLayerWithCellData:
			if debugMode: printDebug(str("setMapAndKeepPosition() useNewData: ", self.tileMapData, " → ", newMap.cellData))
			if newMap.cellData:
				self.tileMapData = newMap.cellData
			else:
				printWarning(str("setMapAndKeepPosition() useNewData: true but newMap has no cellData: ", newMap))
				self.tileMapData = null # NOTE: Yes, clear the data if the new map doesn't have any, to avoid unexpected blocking in empty cells etc.

		# Move over

		var previousMap: TileMapLayer = self.tileMap # Let the TileMap change before changing `currentCellCoordinates`, just in case the property getters/setters do anything.
		self.tileMap = newMap
		self.validateTileMap(false) # not searchForTileMap # TBD: Is this necessary?
		self.currentCellCoordinates = newCoordinates

		# NOTE: Use the actual `currentCellCoordinates` from hereon instead of `newCoordinates`, which may not have been applied if there was an error or bug.
		if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity)

		# TBD: If we were on the way to a different cell during the previous map, keep moving to ensure smooth animations etc.
		var newDestination: Vector2i = Tools.convertCoordinatesBetweenTileMaps(previousMap, previousDestination, self.tileMap)
		if newDestination != self.currentCellCoordinates: self.setDestinationCellCoordinates(newDestination)

		if debugMode: printDebug(str("setMapAndKeepPosition() coordinates: ", previousCoordinates, " → ", self.currentCellCoordinates))
		didSetNewMap.emit(previousMap, previousCoordinates, newMap, self.currentCellCoordinates)
		return self.currentCellCoordinates - previousCoordinates
	# else
	return Vector2i.ZERO # No movement if we didn't move


## 使用新的 [TileMapLayer] 并保留当前单元格坐标，但可能将 Entity 移动到屏幕上的新像素位置。
## 注意：验证当前坐标在新地图中是否未被占用，但不验证边界；坐标可能在新地图的网格之外。
## 返回：Entity 的先前全局位置与新全局位置之间的差异。
func setMapAndKeepCoordinates(newMap: TileMapLayer, useNewData: bool = true) -> Vector2:
	if not newMap or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepCoordinates(): newMap == current map or null: ", newMap))
		return Vector2.ZERO # Nothing to do if nowhere to move!

	var isNewCellVacant: bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = Tools.checkTileAndCellVacancy(newMap, newMap.cellData, self.currentCellCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, self.currentCellCoordinates)

	if debugMode: printDebug(str("setMapAndKeepCoordinates(): ", self.tileMap, " → ", newMap, " @", self.currentCellCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, self.currentCellCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		var previousPosition: Vector2 = parentEntity.global_position
		willSetNewMap.emit(self.tileMap, self.currentCellCoordinates, newMap, self.currentCellCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelDestination(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCellCoordinates`
			Tools.setCellOccupancy(self.tileMapData, self.currentCellCoordinates, false, null) # isOccupied, occupant

		# NOTE: Do not replace our own data until the movement has been validated and the previous cell has been vacated.
		if useNewData and newMap is TileMapLayerWithCellData:
			if debugMode: printDebug(str("setMapAndKeepCoordinates() useNewData: ", self.tileMapData, " → ", newMap.cellData))
			if newMap.cellData:
				self.tileMapData = newMap.cellData
			else:
				printWarning(str("setMapAndKeepCoordinates() useNewData: true but newMap has no cellData: ", newMap))
				self.tileMapData = null # NOTE: Yes, clear the data if the new map doesn't have any, to avoid unexpected blocking in empty cells etc.

		# Move over
		var previousMap: TileMapLayer = self.tileMap
		self.tileMap = newMap
		self.validateTileMap(false) # not searchForTileMap # TBD: Is this necessary?
		if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity)

		# Animate movement to a new pixel position if needed.
		if shouldMoveInstantly:
			snapEntityPositionToTile(self.currentCellCoordinates)
			self.isMovingToNewCell = false
		else:
			self.destinationCellCoordinates = self.currentCellCoordinates # TBD: Necessary?
			self.isMovingToNewCell = true

		if debugMode: printDebug(str("setMapAndKeepCoordinates() position: ", previousPosition, " → ", parentEntity.global_position))
		didSetNewMap.emit(previousMap, self.currentCellCoordinates, newMap, self.currentCellCoordinates)
		return parentEntity.global_position - previousPosition
	# else
	return Vector2.ZERO # No movement if we didn't move

#endregion


#region Per-Frame Updates

func _physics_process(delta: float) -> void:
	# TODO: TBD: Occupy each cell along the way too?
	if not isEnabled: return

	if isMovingToNewCell:
		moveTowardsDestinationCell(delta)
		checkForArrival()
	elif shouldSnapPositionEveryFrame and tileMap != null:
		# If we are already at the destination, keep snapping to the current tile coordinates,
		# to ensure alignment in case the TileMap node is moving.
		snapEntityPositionToTile()

	if debugMode: showDebugInfo()


## 每帧调用以将父 Entity 移动到 [member destinationCellCoordinates] 的屏幕位置。
## 重要：其他脚本不应直接调用此方法；使用 [method setDestinationCellCoordinates] 指定新的地图网格单元格。
func moveTowardsDestinationCell(delta: float) -> void:
	# 待办：处理物理碰撞
	# 待办：待定：也占用沿途的每个单元格？
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates) # 注意：不缓存，因为 TileMap 可能在帧之间移动。
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, speed * delta)
	parentEntity.reset_physics_interpolation() # 检查：必要吗？


## 我们到了吗？
func checkForArrival() -> bool:
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates)
	if parentEntity.global_position == destinationTileGlobalPosition:
		self.currentCellCoordinates = self.destinationCellCoordinates
		self.isMovingToNewCell = false
		didArriveAtNewCell.emit(currentCellCoordinates)
		previousInputVector = inputVector
		inputVector = Vector2i.ZERO
		return true
	else:
		self.isMovingToNewCell = true
		return false


func updateIndicator() -> void:
	if not visualIndicator: return
	if tileMap:
		visualIndicator.global_position = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates)
		visualIndicator.visible = isMovingToNewCell
	else:
		visualIndicator.position = Vector2.ZERO # TBD: Necessary?
		visualIndicator.visible = false

#endregion


#region Debugging

func showDebugInfo() -> void:
	if not debugMode: return
	DebugSystem.addComponentWatchList(self, {
		tileMap				= tileMap,
		entityPosition		= parentEntity.global_position,
		currentCell			= currentCellCoordinates,
		input				= inputVector,
		previousInput		= previousInputVector,
		isMovingToNewCell	= isMovingToNewCell,
		destinationCell		= destinationCellCoordinates,
		destinationPosition	= Tools.getCellGlobalPosition(tileMap, destinationCellCoordinates) if tileMap else Vector2.ZERO,
		})


func onWillStartMovingToNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("willStartMovingToNewCell(): ", newDestination))


func onDidArriveAtNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("onDidArriveAtNewCell(): ", newDestination))

#endregion
