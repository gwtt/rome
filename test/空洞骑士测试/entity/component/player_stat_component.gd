extends CapabilityComponent
class_name PlayerStatComponent

signal stat_changed(name: StringName, new_value: float, delta: float)

var base_stats : = {
	"attack": 10.0,
	"max_hp": 100.0,
	"speed": 500
}

var current_stats : = {
	"hp"      : 100.0,
}

var modifiers : = {}        # { "attack": [ +5, -2, ... ], ... }

func _ready():
	# 校正初始 hp
	current_stats.hp = base_stats.max_hp

# 读取属性（自动把 base+所有加成 累加）
func get_stat(stat_name: StringName) -> float:
	if base_stats.has(stat_name):
		return base_stats[stat_name] + _sum_mods(stat_name)
	elif current_stats.has(stat_name):
		return current_stats[stat_name]
	return 0

func _sum_mods(stat_name):
	if !modifiers.has(stat_name):
		return 0
	var sum := 0.0
	for v in modifiers[stat_name]:
		sum += v
	return sum

# 修改当前类属性（例如 hp 损血回血）
func add_to_stat(stat_name: StringName, delta: float):
	if current_stats.has(stat_name):
		current_stats[stat_name] = clamp(current_stats[stat_name] + delta, 0, get_stat("max_"+stat_name) if stat_name=="hp" else INF)
		emit_signal("stat_changed", stat_name, current_stats[stat_name], delta)

# 添加 / 删除临时修正（BUFF、Debuff 等）
func add_modifier(stat_name: StringName, value: float, source: Object):
	modifiers[stat_name] = modifiers.get(stat_name, [])
	modifiers[stat_name].append({source = source, value = value})
	emit_signal("stat_changed", stat_name, get_stat(stat_name), value)

func remove_modifiers_from(source: Object):
	for stat in modifiers.keys():
		for m in modifiers[stat].duplicate():
			if m.source == source:
				modifiers[stat].erase(m)
				emit_signal("stat_changed", stat, get_stat(stat), -m.value)
