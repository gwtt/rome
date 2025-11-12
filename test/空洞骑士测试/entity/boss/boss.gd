extends CharacterBody2D

@export var boss_stat_component: BossStatsComponent
var player:Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("空洞骑士")
	boss_stat_component.player = player
