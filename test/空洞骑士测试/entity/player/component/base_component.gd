extends Node
class_name BaseComponent

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree
@export var player_stat_component: PlayerStatsComponent
@export var boss_stat_component: BossStatsComponent
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
