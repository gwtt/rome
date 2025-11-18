extends CharacterBody2D

var direction = 1: 
	set(value):
		direction = value
		turn_direction(value)
		
const SPEED = 400.0

func turn_direction(value) -> void:
	self.scale.x = value

func _physics_process(_delta: float) -> void:
	velocity.x = SPEED * direction
	move_and_slide()


func _on_black_wave_hit_box_area_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if not enemy:
		return
	var damage_value = 30
	
	# 查找敌人的 DamageableComponent（支持 Boss、小怪等所有可受伤实体）
	var damageable = _find_damageable_component(enemy)
	if damageable:
		var damage_info = DamageInfo.new(damage_value, owner, "黑波")
		damageable.take_damage(damage_info)


## TODO 优化成通用型
## 查找敌人身上的 DamageableComponent
## 支持多种查找方式，确保兼容性
func _find_damageable_component(enemy: Node) -> DamageableComponent:
	# 方式1: 直接查找 DamageableComponent
	var damageable = enemy.get_node_or_null("DamageableComponent")
	if damageable and damageable is DamageableComponent:
		return damageable
	
	# 方式2: 查找 BossHurtComponent（继承自 DamageableComponent）
	var boss_hurt = enemy.get_node_or_null("BossHurtComponent")
	if boss_hurt and boss_hurt is DamageableComponent:
		return boss_hurt
	
	# 方式3: 遍历所有子节点查找
	for child in enemy.get_children():
		if child is DamageableComponent:
			return child
	
	return null
