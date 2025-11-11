extends BaseComponent
class_name PlayerHurtComponent

@export var hurt_box: CollisionPolygon2D
@export var sprite: Sprite2D

## 总共无敌时间
const HURT_TOTAL = 2
## 受伤时间
var hurt_time: float = 0
var TWINKLE_INTERVAL: float = 0.1
func _on_hurt_state_entered() -> void:
	stat_component.is_hurting = true
	state_machine.travel("受击")	
	hurt_time = 0
	hurt_box.call_deferred("set_disabled", true)
	
	while hurt_time < HURT_TOTAL:
		hurt_time += TWINKLE_INTERVAL
		await get_tree().create_timer(TWINKLE_INTERVAL).timeout
		sprite.visible = !sprite.visible
		
	sprite.visible = true
	hurt_box.call_deferred("set_disabled", false)
	
func _on_hurt_state_physics_processing(_delta: float) -> void:
	owner.velocity.y += stat_component.gravity * _delta
	var current_pos := state_machine.get_current_play_position()
	var current_len := state_machine.get_current_length()
	if current_pos >= current_len:
		stat_component.state_chart.send_event("to_normal")
		stat_component.is_hurting = false	

func _on_hurt_box_area_area_entered(_area: Area2D) -> void:
	stat_component.state_chart.send_event("to_hurt")
	owner.velocity.y = -150
	if owner.global_position < _area.global_position:
		owner.velocity.x = -150
	else:
		owner.velocity.x = 150
