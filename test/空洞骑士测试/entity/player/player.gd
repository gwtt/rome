extends CharacterBody2D

@onready var player_stats_component: PlayerStatsComponent = $PlayerStatsComponent
@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(_delta: float) -> void:
	turn_direction()
	move_and_slide()
	
## 旋转方向
func turn_direction() -> void:
	if velocity.x != 0:
		sprite.scale.x = -1 if velocity.x < 0 else 1

