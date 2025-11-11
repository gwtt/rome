extends Node

@onready var path_camera: PhantomCamera2D = $PathCamera
@onready var none_camera: PhantomCamera2D = $NoneCamera

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("空洞骑士"):
		none_camera.priority = 5
