extends BaseComponent
class_name BossHurtComponent

@export var sprite: Sprite2D

const HURT_INTERVAL = 0.1

func _ready() -> void:
	sprite.use_parent_material = true

func _on_hurt_state_entered() -> void:
	sprite.use_parent_material = false
	await get_tree().create_timer(HURT_INTERVAL).timeout
	sprite.use_parent_material = true
	boss_component.state_chart.send_event("to_normal")
	
func _on_normal_state_physics_processing(delta: float) -> void:
	state_machine.travel("站立")

func _on_hurt_box_area_area_entered(area: Area2D) -> void:
	boss_component.state_chart.send_event("to_hurt")
