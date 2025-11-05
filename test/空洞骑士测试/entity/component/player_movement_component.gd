extends CapabilityComponent
class_name PlayerMoveMentComponent

@export var accelerate_speed := 2000.0
@export var max_speed := 120.0
@export var acceleration := 1200.0
@export var deceleration := 800.0
@export var gravity := 580
@export var jump_speed := 280
@export var jump_higher := 4
var velocity : Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO      # 记录本帧输入方向（可供动画用）

func get_speed() -> float:
	return velocity.length()

func stop():
	velocity = Vector2.ZERO
