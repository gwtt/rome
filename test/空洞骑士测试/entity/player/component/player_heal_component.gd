extends BaseComponent
class_name PlayerSkillComponent

@export var black_wave: PackedScene
@export var shout: PackedScene
@export var crash_down: PackedScene
@export var hurt_box: CollisionPolygon2D

## 1代表下砸蓄力，2代表下砸下落，3代表下砸落地
var crach_down_status = 1
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("black_wave") and Input.get_action_strength("moveUp")  and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.shout
		player_stat_component.state_chart.send_event("to_skill")
		return	
	if Input.is_action_just_pressed("black_wave") and Input.get_action_strength("moveDown") and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.crash_down
		player_stat_component.state_chart.send_event("to_skill")
		return		
	if Input.is_action_just_pressed("black_wave") and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.black_wave
		player_stat_component.state_chart.send_event("to_skill")
		return

func _on_skill_state_physics_processing(delta: float) -> void:
	if player_stat_component.skill_type == player_stat_component.SkillType.heal:
		owner.add_gravity(delta)
	if player_stat_component.skill_type == player_stat_component.SkillType.crash_down:
		if crach_down_status == 2:
			owner.add_gravity(delta)
			if owner.is_on_floor():
				owner.velocity = Vector2.ZERO
				crach_down_status = 3
				state_machine.travel("下砸落地")
				return
		var current_pos := state_machine.get_current_play_position()
		var current_len := state_machine.get_current_length()
		if current_pos >= current_len:
			if crach_down_status == 1:
				owner.velocity.y = 600
				crach_down_status = 2
				state_machine.travel("下砸下落过程")
				
func heal() -> void:
	player_stat_component.player_data.soul -= 3
	player_stat_component.player_data.health += 5
	player_stat_component.state_chart.send_event("to_normal")	

var black_wave_interval := 20
func generate_black_wave() -> void:
	var wave := SpawnerSystem.spawn(black_wave, owner.get_parent(), owner.global_position + Vector2(black_wave_interval * player_stat_component.direction_x , 0))
	wave.direction = player_stat_component.direction_x
	player_stat_component.player_data.soul -= 3
	player_stat_component.state_chart.send_event("to_normal")

func generate_shout() -> void:
	var shout_scene := SpawnerSystem.spawn(shout, owner.get_parent(), owner.global_position)
	player_stat_component.player_data.soul -= 3
	shout_scene.tree_exiting.connect(func(): player_stat_component.state_chart.send_event("to_normal"))

func generate_crash_down() -> void:
	var crash_down_scene := SpawnerSystem.spawn(crash_down, owner.get_parent(), owner.global_position)
	crash_down_scene.tree_exiting.connect(
		func():
			player_stat_component.state_chart.send_event("to_normal")
			await get_tree().create_timer(0.5).timeout 
			hurt_box.call_deferred("set_disabled", false)
	)


func _on_skill_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	set_physics_process(false)
	if player_stat_component.skill_type == player_stat_component.SkillType.heal:
		state_machine.travel("回血")
	if player_stat_component.skill_type == player_stat_component.SkillType.black_wave:	
		state_machine.travel("黑波")
	if player_stat_component.skill_type == player_stat_component.SkillType.shout:
		state_machine.travel("上吼")
	if player_stat_component.skill_type == player_stat_component.SkillType.crash_down:
		## TODO 需要实现锁机制，比如多个地方封住hurt_box，不能一个地方解锁就放行
		hurt_box.call_deferred("set_disabled", true)
		player_stat_component.player_data.soul -= 3
		crach_down_status = 1
		state_machine.travel("下砸蓄力")

func _on_skill_state_exited() -> void:
	set_physics_process(true)
