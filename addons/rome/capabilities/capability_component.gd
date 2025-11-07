extends Node
class_name CapabilityComponent

@export var default_sheets : Array[CapabilitySheet]

var tag_blockers: Dictionary[Enums.CapabilityTags, Array] = {}
var default_capabilities: Array = []
# 所有注册到此组件的 capability，用于快速更新阻塞状态
var all_capabilities: Array[BaseCapability] = []

func _ready(): 
	_load_sheets(default_sheets)
	
func runtime_add_sheet(sheet: CapabilitySheet):  
	_load_sheets([sheet])  
  
func _load_sheets(sheets: Array[CapabilitySheet]):  
	for sheet: CapabilitySheet in sheets:  
		var caps = sheet.instantiate(get_parent())  
		for cap: BaseCapability in caps:  
			cap.owner = get_parent()  
			cap.setup()  
			CapabilitySystem.register(cap)  
			default_capabilities.append(cap)
			
## 阻塞标签
func block_capabilities(tag: Enums.CapabilityTags, capability: BaseCapability) -> void:
	#DebugSystem.printHighlight("阻塞了标签:" + str(tag), capability)
	if !tag_blockers.has(tag):
		tag_blockers[tag] = []
	if tag_blockers[tag].has(capability):
		return	
	tag_blockers[tag].append(capability)
	# 更新所有相关 capability 的阻塞状态
	_update_capabilities_blocked_state(tag)

func unblock_capabilities(tag: Enums.CapabilityTags, capability: BaseCapability) -> void:
	#DebugSystem.printHighlight("解锁了标签:" + str(tag), capability)
	if !tag_blockers.has(tag):
		return
	tag_blockers[tag].erase(capability)
	# 更新所有相关 capability 的阻塞状态
	_update_capabilities_blocked_state(tag)

## 是否阻塞
func is_block(tag: Enums.CapabilityTags) -> bool:
	if tag_blockers.has(tag):
		if tag_blockers[tag].size() == 0:
			return false
		else:
			return true
	else:
		return false

## 更新所有 capability 的阻塞状态（当标签阻塞状态改变时调用）
func _update_capabilities_blocked_state(changed_tag: Enums.CapabilityTags) -> void:
	for cap: BaseCapability in all_capabilities:
		# 如果这个 capability 包含被改变的标签，更新其阻塞状态
		if changed_tag in cap.tags:
			_update_single_capability_blocked_state(cap)

## 更新单个 capability 的阻塞状态
func _update_single_capability_blocked_state(cap: BaseCapability) -> void:
	# 检查 capability 的所有标签，如果任何一个被阻塞，则整个 capability 被阻塞
	cap.is_blocked = false
	for tag in cap.tags:
		if is_block(tag):
			cap.is_blocked = true
			break

## 注册 capability 到组件（由 capability 的 _ready 调用）
func register_capability(cap: BaseCapability) -> void:
	if not cap in all_capabilities:
		all_capabilities.append(cap)
		# 初始化阻塞状态
		_update_single_capability_blocked_state(cap)

## 从组件中注销 capability（由 capability 销毁时调用）
func unregister_capability(cap: BaseCapability) -> void:
	all_capabilities.erase(cap)
