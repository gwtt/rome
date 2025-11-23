extends DamageableComponent
class_name BossHurtComponent

@export var sprite: Sprite2D
@export var boss_stats_component: BossStatsComponent
@export var hit_particle: PackedScene

const HURT_INTERVAL = 0.1

## 血量阈值，触发僵直状态
const HEALTH_THRESHOLDS = [750, 500, 250]
## 已触发的阈值，避免重复触发
var triggered_thresholds: Array[int] = []

func _ready() -> void:
	sprite.use_parent_material = true

func _on_hurt_box_area_area_entered(_area: Area2D) -> void:
	hurt()

func hurt() -> void:
	sprite.use_parent_material = false
	await get_tree().create_timer(HURT_INTERVAL).timeout
	sprite.use_parent_material = true

## 实现 DamageableComponent 接口
func take_damage(damage_info: DamageInfo) -> void:
	if not boss_stats_component or not boss_stats_component.boss_data:
		return
	
	SpawnerSystem.spawn(hit_particle, owner)
	# 记录扣除血量前的血量
	var previous_health = boss_stats_component.boss_data.health
	
	# 如果 Boss 在僵直状态，受到攻击时立即转为 normal 状态
	if boss_stats_component.is_stiff:
		boss_stats_component.state_chart.send_event("to_normal")
		DebugSystem.printDebug("Boss 在僵直状态受到攻击，转为 normal 状态", owner)
	
	# 扣除血量
	boss_stats_component.boss_data.health -= damage_info.damage
	DebugSystem.printDebug("Boss 受到 %d 点伤害，剩余血量: %d" % [damage_info.damage, boss_stats_component.boss_data.health], owner)
	
	# 检查血量阈值，触发僵直状态（只有在非僵直状态下才触发新的僵直）
	if not boss_stats_component.is_stiff:
		_check_health_thresholds(previous_health, boss_stats_component.boss_data.health)
	
	# 触发受伤效果
	hurt()
	
	# 检查是否死亡
	if boss_stats_component.boss_data.health <= 0:
		boss_stats_component.state_chart.send_event("to_die")

## 检查血量是否降到阈值，触发僵直状态
func _check_health_thresholds(previous_health: int, current_health: int) -> void:
	# 从高到低检查每个阈值
	for threshold in HEALTH_THRESHOLDS:
		# 如果该阈值已经触发过，跳过
		if threshold in triggered_thresholds:
			continue
		
		# 如果血量从阈值以上降到阈值以下，触发僵直
		if previous_health > threshold and current_health <= threshold:
			triggered_thresholds.append(threshold)
			boss_stats_component.state_chart.send_event("to_stiff")
			DebugSystem.printDebug("Boss 血量降至 %d，触发僵直状态" % threshold, owner)
			break  # 一次伤害只触发一个阈值
