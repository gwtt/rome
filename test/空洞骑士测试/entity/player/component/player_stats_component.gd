extends BaseComponent
class_name PlayerStatsComponent

@export var player_data: PlayerData

@export var horizontal_accelerate_speed := 2000.0
@export var max_speed := 120.0
@export var dash_speed := 400.0
@export var gravity := 580
@export var jump_speed := 280
@export var double_jump_speed := 240
@export var jump_higher := 4
@export var state_chart:StateChart
@export var has_black_dash = true

var direction_x: int
var flip_h: bool
var can_dash: bool
var first_jump_over: bool
var can_jump: bool
var can_double_jump: bool
var is_double_jumping: bool
var is_hurting: bool
var skill_type: SkillType

enum SkillType {
	none = 0,
	heal = 1,
	black_wave = 2,
	shout = 3
}
#func _physics_process(delta: float) -> void:
	#if state_machine.get_current_node().begins_with("横劈"):
		#DebugSystem.printHighlight(state_machine.get_current_node(), owner)
