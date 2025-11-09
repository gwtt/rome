extends Node
class_name BaseComponent

@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree
@export var stat_component: PlayerStatsComponent
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
