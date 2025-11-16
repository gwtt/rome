extends CharacterBody2D
class_name Player

@onready var player_stats_component: PlayerStatsComponent = $PlayerStatsComponent

@onready var hurt_box_area: Area2D = $HurtBoxArea
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(_delta: float) -> void:
	turn_direction()
	move_and_slide()

## 旋转方向
func turn_direction() -> void:
	## 受伤要方向颠倒
	var direction = 1 if player_stats_component.is_hurting else -1
	if velocity.x != 0:
		sprite.scale.x = direction if velocity.x < 0 else 1
		hurt_box_area.scale.x = direction if velocity.x < 0 else 1
		attack_area.scale.x = direction if velocity.x < 0 else 1
		player_stats_component.flip_h = false if velocity.x < 0 else true
