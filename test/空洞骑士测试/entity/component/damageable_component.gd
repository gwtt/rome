extends Node
class_name DamageableComponent

## 可受伤组件的基类
## 所有可受伤的实体都应该有一个继承此类的组件

## 接收伤害的接口，子类需要实现
func take_damage(_damage_info: DamageInfo) -> void:
	push_error("DamageableComponent.take_damage() 必须在子类中实现")
