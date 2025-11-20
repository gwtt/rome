extends BaseComponent
class_name BossReadyComponent

@export var shout: PackedScene
var is_start := 0

func _on_ready_state_entered() -> void:
	EventBugSystem.subscribe("boss_start", on_boss_start)

func on_boss_start() -> void:
	owner.turn_direction()
	await get_tree().create_timer(1.0).timeout
	is_start = 1

func _on_ready_state_exited() -> void:
	EventBugSystem.unsubscribe("boss_start", on_boss_start)

func _on_ready_state_physics_processing(delta: float) -> void:
	if is_start == 1:
		state_machine.travel("下落")
		owner.add_gravity(delta)
		if owner.is_on_floor():
			state_machine.travel("战吼准备")
			is_start = 2
	if is_start == 3:
		owner.shake_camera(15)
		
var shout_scene: Node2D
func generate_shout() -> void:
	shout_scene = SpawnerSystem.spawn(shout, owner.get_parent(), owner.global_position)

func delete_shout() -> void:
	shout_scene.call_deferred("queue_free")

func set_start_value(value: int) -> void:
	is_start = value
