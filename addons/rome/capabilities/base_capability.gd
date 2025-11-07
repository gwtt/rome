extends Node
class_name BaseCapability

#region 标签
@export var tags: Array[Enums.CapabilityTags]
@export  var tick_group: Enums.ETickGroup = Enums.ETickGroup.GamePlay
@export var tick_group_order = 100
#endregion
var active := false;

# 激活持续时间
var active_duration: float = 0
# 非激活持续时间
var deactive_duration: float = 0
var capability_component: CapabilityComponent
var component: CapabilityComponent
# 阻塞状态缓存，避免每帧检查
var is_blocked: bool = false


func _ready() -> void:
	await owner.ready
	component = get_node("..")
	capability_component = owner.get_node_or_null("CapabilityComponent") 
	set_up()
	# 注册到 capability_component，用于阻塞状态管理
	if capability_component:
		capability_component.register_capability(self)
	owner.tree_exiting.connect(on_owner_destroyed)

# GameObject实例化时启动, 主动激活
func set_up() -> void:
	CapabilitySystem.register(self)

# 激活状态时每帧检查
func should_activate() -> bool:
	return true

# 非激活状态时每帧检查
func should_deactivate() -> bool:
	return false

# 激活时运行
func on_active() -> void:
	pass

# 非激活时运行
func on_deactivate() -> void:
	pass

# 激活时,每帧运行
func tick_active(_delta_time: float) -> void:
	pass

# 拥有者摧毁时
func on_owner_destroyed():
	if (active):
		on_deactivate()
	# 从 component 中移除
	if capability_component:
		capability_component.unregister_capability(self)
	CapabilitySystem.unregister(self)

# 切换激活状态,返回切换后的值
func toggle() -> bool:
	if should_activate() && active == false:
		active = true
		on_active()
		return true

	if should_deactivate() && active == true:
		active = false
		on_deactivate()
		return false

	if should_deactivate() && active == false:
		return false

	if should_activate() && active == true:
		return true

	return false
