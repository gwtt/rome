extends CapabilityComponent
class_name PlayerMoveComponent

@export var max_speed     : float = 400.0
@export var acceleration  : float = 1200.0
@export var deceleration  : float = 800.0

var velocity : Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO      # 记录本帧输入方向（可供动画用）

func get_speed() -> float:
	return velocity.length()

func stop():
	velocity = Vector2.ZERO
