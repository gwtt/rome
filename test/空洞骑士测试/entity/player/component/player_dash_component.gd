extends BaseComponent
class_name PlayerDashComponent

@export var hurt_box: CollisionPolygon2D
@export var collision_polygon_2d: CollisionPolygon2D
@export var player_black_dash_component: PlayerBlackDashComponent

func _on_dash_state_entered() -> void:
	var velocity: Vector2 = owner.velocity
	var dash_direction = sign(velocity.x)

	player_stat_component.can_dash = false
	if player_stat_component.has_black_dash:
		player_stat_component.has_black_dash = false
		player_black_dash_component.spawn_blackdash()
		state_machine.travel("黑冲")
		hurt_box.call_deferred("set_disabled", true)
		#owner.call_deferred("set_collision_mask", 0)
		#collision_polygon_2d.call_deferred("set_disabled", true)
	else:
		state_machine.travel("冲刺")

	velocity.x = player_stat_component.dash_speed * dash_direction
	velocity.y = 0
	owner.velocity = velocity

func _on_dash_state_physics_processing(delta: float) -> void:
	var velocity: Vector2 = owner.velocity
	velocity.x = lerp(0.0, velocity.x, pow(2, -6 * delta))
	owner.velocity = velocity

	var current_pos := state_machine.get_current_play_position()
	var current_len := state_machine.get_current_length()

	if current_pos >= current_len:
		player_stat_component.state_chart.send_event("to_movement")
		hurt_box.call_deferred("set_disabled", false)
		#owner.call_deferred("set_collision_mask", 1)
		#collision_polygon_2d.call_deferred("set_disabled", false)

func on_dash_finished(anim_name: StringName) -> void:
	if anim_name == "冲刺":
		player_stat_component.state_chart.send_event("to_movement")
	DebugSystem.printDebug(anim_name + "结束", self, "red")

func _on_move_ment_state_physics_processing(_delta: float) -> void:
	if Input.is_action_just_pressed("dash") and player_stat_component.can_dash:
		var velocity: Vector2 = owner.velocity
		var dash_direction = sign(velocity.x)
		if dash_direction == 0: return
		player_stat_component.state_chart.send_event("to_dash")
