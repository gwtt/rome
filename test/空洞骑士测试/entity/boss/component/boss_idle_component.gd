extends BaseComponent
class_name BossIdleComponent


func _on_idle_state_physics_processing(_delta: float) -> void:
	turn_direction()
	
## 旋转方向
func turn_direction() -> void:
	if boss_stat_component.player:
		var direction = 1 if boss_stat_component.player.global_position < owner.global_position else -1
		owner.scale.x = direction

func _on_idle_state_entered() -> void:
	state_machine.travel("站立")
