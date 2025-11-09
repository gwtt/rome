## 在运行时为 [TileMapLayer] 的每个单元格存储自定义数据。
## 由组件（如 [TileBasedPositionComponent]）使用，例如用于确定单元格是否被占用，或者如果它是可破坏的，则确定其剩余的"生命值"。
## 注意："CELLS"（单元格）是单个网格元素，而不是"TILES"（瓦片）；
## 瓦片是 [TileSet] 中的永久资源。单个瓦片用于绘制 [TileMapLayer] 的多个单元格。
## [TileSet] 可以为每个瓦片指定自定义数据，但 [TileMapLayer] 在没有此脚本的情况下无法为每个网格单元格添加自定义数据。
## 有关内置支持自定义数据的独立 [TileMapLayer]，请参阅 [TileMapLayerWithCellData]

class_name TileMapCellData
extends Resource


#region Parameters & State

## 字典的字典。{ 单元格坐标 : {键 : 值} }
## 每个 (x,y) [Vector2i] 坐标键包含一个 {[StringName]: [Variant]} 的字典。
## 注意：此数据在游戏过程中由组件（如 [TileBasedPositionComponent]）动态设置，例如用于确定单元格是否被占用。
@export_storage var dataDictionary: Dictionary[Vector2i, Dictionary]

@export var debugMode: bool = false

#endregion


#region State
var associatedTileMaps: Array[TileMapLayer] ## 此数据结构表示的 [TileMapLayer] 列表。由 [TileBasedPositionComponent] 等设置。
#endregion


#region Data Interface

func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if debugMode: DebugSystem.printDebug(str("setCellData() @", coordinates, " ", key, " = ", value), self)

	# 注意：不要在这里分配整个字典，否则会覆盖所有其他键！

	# 获取单元格的数据字典，或添加一个空字典。
	var cellData: Variant = dataDictionary.get_or_add(coordinates, {}) # 如果坐标键缺失，则无法将其类型化为 `Dictionary` :(

	cellData[key] = value


func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	var cellData: Variant = dataDictionary.get(coordinates) # 如果坐标键缺失，则无法将其类型化为 `Dictionary` :(
	var value: Variant

	if cellData is Dictionary:
		value = (cellData as Dictionary).get(key)
	else:
		value = null

	if debugMode: DebugSystem.printDebug(str("getCellData() @", coordinates, " ", key, ": ", value), self)
	return value

#endregion
