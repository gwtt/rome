extends Node

@onready var path_camera: PhantomCamera2D = $PathCamera
@onready var none_camera: PhantomCamera2D = $NoneCamera

var boss_end = false

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player and boss_end == true:
		none_camera.priority = 0
		path_camera.priority = 5

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and none_camera.priority != 5:
		EventBugSystem.push_event("boss_start")
		none_camera.priority = 5
		path_camera.priority = 0
