extends BaseComponent
class_name PlayerSkillComponent

@export var black_wave: PackedScene
@export var shout: PackedScene

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("black_wave") and Input.get_action_strength("moveUp")  and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.shout
		player_stat_component.state_chart.send_event("to_skill")
		return	
	if Input.is_action_just_pressed("black_wave") and player_stat_component.player_data.soul >= 3:
		player_stat_component.skill_type = player_stat_component.SkillType.black_wave
		player_stat_component.state_chart.send_event("to_skill")
		return
		

func _on_skill_state_physics_processing(delta: float) -> void:
	if player_stat_component.skill_type == player_stat_component.SkillType.heal:
		owner.add_gravity(delta)

func heal() -> void:
	player_stat_component.player_data.soul -= 3
	player_stat_component.player_data.health += 5
	player_stat_component.state_chart.send_event("to_normal")	

var interval := 20
func generate_black_wave() -> void:
	var wave := SpawnerSystem.spawn(black_wave, owner.get_parent(), owner.global_position + Vector2(interval * player_stat_component.direction_x , 0))
	wave.direction = player_stat_component.direction_x
	player_stat_component.player_data.soul -= 3
	player_stat_component.state_chart.send_event("to_normal")

func generate_shout() -> void:
	var shout_scene := SpawnerSystem.spawn(shout, owner.get_parent(), owner.global_position)
	player_stat_component.player_data.soul -= 3
	shout_scene.tree_exiting.connect(func(): player_stat_component.state_chart.send_event("to_normal"))
	

func _on_skill_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	set_physics_process(false)
	if player_stat_component.skill_type == player_stat_component.SkillType.heal:
		state_machine.travel("回血")
	if player_stat_component.skill_type == player_stat_component.SkillType.black_wave:	
		state_machine.travel("黑波")
	if player_stat_component.skill_type == player_stat_component.SkillType.shout:
		state_machine.travel("上吼")


func _on_skill_state_exited() -> void:
	set_physics_process(true)
