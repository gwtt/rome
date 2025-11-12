extends BaseComponent
class_name BossHurtComponent

@export var sprite: Sprite2D

const HURT_INTERVAL = 0.1

func _ready() -> void:
	sprite.use_parent_material = true

func _on_hurt_box_area_area_entered(_area: Area2D) -> void:
	hurt()

func hurt() -> void:
	sprite.use_parent_material = false
	await get_tree().create_timer(HURT_INTERVAL).timeout
	sprite.use_parent_material = true
