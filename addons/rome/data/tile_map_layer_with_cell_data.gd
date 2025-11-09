## 带有 [TileMapCellData] 资源的 [TileMapLayer]，用于在运行时为单个单元格存储自定义数据，
## 例如单元格是否被实体占用，或者如果它是可破坏的，则存储其"生命值"等。

class_name TileMapLayerWithCellData
extends TileMapLayer


#region Parameters & State

@export var cellData: TileMapCellData ## 如果为 `null`，则在 [method _ready] 时创建新结构

@export var shouldCreateCellData: bool = true

@export var debugMode: bool = false:
	set(newValue):
		if newValue != debugMode:
			debugMode = newValue
			if cellData: cellData.debugMode = self.debugMode

#endregion


func _ready() -> void:
	if not cellData and shouldCreateCellData:
		if debugMode: DebugSystem.printDebug("No TileMapCellData, creating new.", self)
		self.cellData = TileMapCellData.new()
	
	if cellData: # 单独的 `if`，以防 `cellData` 由前一个 `if` 创建
		cellData.debugMode = self.debugMode


#region Data Interface

func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if cellData: cellData.setCellData(coordinates, key, value)
	else: DebugSystem.printWarning("setCellData(): No TileMapCellData!", self)


func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	if cellData: 
		return cellData.getCellData(coordinates, key)
	else: 
		DebugSystem.printWarning("getCellData(): No TileMapCellData!", self)
		return null

#endregion
