extends Node2D
class_name PlayerBlackDashComponent

@export var stat_component: PlayerStatsComponent
@export var audio_system: Node

func _ready() -> void:
	$AnimationPlayer.animation_finished.connect(gather)

func spawn_blackdash():
	$AnimationPlayer.play("聚集")

func gather(_anim_name: StringName) -> void:
	audio_system.play_audio_2d("黑冲cd恢复")
	stat_component.has_black_dash = true
