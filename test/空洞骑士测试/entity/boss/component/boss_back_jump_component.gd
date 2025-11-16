extends BaseComponent
class_name BossBackJumpComponent

## 后跳并释放白波
@export var wave_light: PackedScene
@export var jump_speed := 400
@export var left_point := Vector2.ZERO
@export var right_point := Vector2.ZERO

## 是否释放白波
var is_light_wave := false
func _on_back_jump_state_physics_processing(delta: float) -> void:
	owner.add_gravity(delta)
	
	if is_light_wave:
		var current_pos := state_machine.get_current_play_position()
		var current_len := state_machine.get_current_length()
		if current_pos >= current_len:
			boss_stat_component.state_chart.send_event("to_idle")
		return
		
	if owner.velocity.y > 0:
		if sign(owner.velocity.x) == sign(boss_stat_component.direction_x):
			state_machine.travel("下落")
		else:
			state_machine.travel("后跳下落")
	
	## 必须加个后面条件
	if owner.is_on_floor() and not is_light_wave:
		if randf() < 0.5:
			is_light_wave = true
			owner.velocity = Vector2.ZERO
			state_machine.travel("白波")
		else:
			boss_stat_component.state_chart.send_event("to_dash")

func _on_back_jump_state_entered() -> void:
	is_light_wave = false
	owner.velocity.y = -jump_speed
	var player_position = boss_stat_component.player.global_position
	var boss_positon = owner.global_position
	owner.velocity.x = left_point.x - boss_positon.x if player_position.x > (left_point.x + right_point.x) / 2.0 else right_point.x - boss_positon.x
	if sign(owner.velocity.x) == sign(boss_stat_component.direction_x):
		state_machine.travel("跳跃")
	else:
		state_machine.travel("后跳")

var interval := 20
func generate_wave_light() -> void:
	var light_wave := SpawnerSystem.spawn(wave_light, owner.get_parent(), owner.global_position + Vector2(interval * boss_stat_component.direction_x , 0))
	light_wave.direction = boss_stat_component.direction_x
