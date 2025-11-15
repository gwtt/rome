extends BaseComponent
class_name BossReadyComponent


func _on_ready_state_physics_processing(_delta: float) -> void:
	state_machine.start("准备")

func _on_ready_state_entered() -> void:
	EventBugSystem.subscribe("boss_start", on_boss_start)

func on_boss_start() -> void:
	boss_stat_component.state_chart.send_event("to_idle")

func _on_ready_state_exited() -> void:
	EventBugSystem.unsubscribe("boss_start", on_boss_start)
