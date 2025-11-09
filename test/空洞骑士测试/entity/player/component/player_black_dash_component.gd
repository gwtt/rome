extends Node2D
class_name PlayerBlackDashComponent

@export var stat_component: PlayerStatsComponent

func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(gather)

func spawn_blackdash():
	$AnimationPlayer.play("聚集")

func gather(_anim_name: StringName) -> void:
	stat_component.has_black_dash = true
