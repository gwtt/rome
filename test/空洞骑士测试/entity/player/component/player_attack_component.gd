extends BaseComponent
class_name PlayerAttackComponent

var attack_index := 1
var attack_time := 0.0
var attack_interval := 0.2

## 不同攻击类型的伤害配置
var attack_damage: Dictionary = {
	"横劈1": 13,
	"横劈2": 13,
	"上劈": 13,
	"下劈": 13
}
@export var noise_emitter: PhantomCameraNoiseEmitter2D

func _on_attack_state_physics_processing(_delta: float) -> void:
	attack_time += _delta
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveDown") and not owner.is_on_floor() and attack_time > attack_interval:
		DebugSystem.printDebug("下劈", owner)
		state_machine.start("下劈")
		attack_time= 0
	if Input.is_action_just_pressed("attack") and Input.get_action_strength("moveUp") and attack_time > attack_interval:
		DebugSystem.printDebug("上劈", owner)
		state_machine.start("上劈")
		attack_time= 0	
	if Input.is_action_just_pressed("attack") and attack_time > attack_interval:
		DebugSystem.printDebug("横劈" + str(attack_index), owner)
		state_machine.start("横劈" + str(attack_index))
		attack_index = attack_index % 2 + 1
		attack_time= 0
	
## https://github.com/godotengine/godot/issues/110128 bug问题
func _on_attack_area_area_entered(_area: Area2D) -> void:
	owner.shake_camera(5.0)
	# 获取被攻击的敌人实体（HurtBoxArea 的父节点）
	var enemy = _area.get_parent()
	if not enemy:
		return
	
	# 获取当前攻击类型
	var current_anim = state_machine.get_current_node()
	var damage_value = attack_damage.get(current_anim, 13)  # 默认伤害值
	
	# 查找敌人的 DamageableComponent（支持 Boss、小怪等所有可受伤实体）
	var damageable = _find_damageable_component(enemy)
	if damageable:
		var damage_info = DamageInfo.new(damage_value, owner, current_anim)
		damageable.take_damage(damage_info)
	
	player_stat_component.player_data.soul += 1
	if current_anim == "下劈":
		player_stat_component.can_double_jump = true
		player_stat_component.can_dash = true
		player_stat_component.is_double_jumping = false
		var velocity: Vector2 = owner.velocity
		velocity.x = 0
		velocity.y = -200
		owner.velocity = velocity
		state_machine.travel("下劈")
		return
	if current_anim == "上劈":
		return
	if player_stat_component.direction_x == 1:
		owner.global_position.x -= 5
	else:
		owner.global_position.x += 5

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

