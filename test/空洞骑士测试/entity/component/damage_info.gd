## 伤害信息类，用于传递伤害相关数据
class_name DamageInfo
extends RefCounted

## 伤害值
var damage: int
## 伤害来源（攻击者）
var source: Node
## 伤害类型（可选，用于扩展）
var damage_type: String = ""

func _init(dmg: int, src: Node, type: String = ""):
	damage = dmg
	source = src
	damage_type = type
