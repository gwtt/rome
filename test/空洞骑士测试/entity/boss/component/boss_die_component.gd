extends BaseComponent
class_name BossDieComponent

@export var body_hit_box:CollisionPolygon2D
@export var hurt_box_area:CollisionPolygon2D

func _on_die_state_entered() -> void:
	owner.velocity = Vector2.ZERO
	state_machine.travel("僵直")
	body_hit_box.call_deferred("set_disabled", true)
	hurt_box_area.call_deferred("set_disabled", true)
	
func _on_die_state_physics_processing(delta: float) -> void:
	owner.add_gravity(delta)

func boss_die():
	EventBugSystem.push_event("boss_end")
