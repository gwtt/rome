extends BaseCapability
class_name PlayerMoveCapability

@export var input_left  : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_up    : String = "ui_up"
@export var input_down  : String = "ui_down"

var body : CharacterBody2D              # Player 本体

func on_active():
	body = owner as CharacterBody2D

func tick_active(delta):
	# 1. 收集输入
	component.input_dir = Vector2(
		Input.get_action_strength(input_right) - Input.get_action_strength(input_left),
		Input.get_action_strength(input_down)  - Input.get_action_strength(input_up)
	).normalized()

	# 2. 计算速度
	var target = component.input_dir * component.max_speed
	var accel  = component.acceleration if component.input_dir.length() > 0.01 else component.deceleration
	component.velocity = component.velocity.move_toward(target, accel * delta)

	# 3. 把结果写回 CharacterBody2D 并推进物理
	body.velocity = component.velocity
	body.move_and_slide()
