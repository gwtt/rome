extends CapabilityComponent
class_name PlayerMoveMentComponent

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var horizontal_accelerate_speed := 2000.0
@export var max_speed := 120.0
@export var dash_speed := 400.0
@export var gravity := 580
@export var jump_speed := 280
@export var double_jump_speed := 240
@export var jump_higher := 4

var can_dash: bool = true
var is_dashing: bool = false
var dash_finished_callback: Callable  # Dash 动画结束的回调

var can_jump: bool = true
var can_double_jump: bool = false
var is_double_jumping: bool = false

func _ready():
	super._ready()
	animation_player.animation_finished.connect(_on_animation_finished)

## 播放动画
func play_anim(anim_name: String, callback: Callable = Callable()) -> void:
	if !animation_player.has_animation(anim_name):
		DebugSystem.printWarning("玩家角色无动画:" + anim_name)
		return
	animation_player.play(anim_name)
	# 注意：dash 回调由 dash_capability 直接设置，不通过 play_anim 参数传递

## 动画播放结束回调
func _on_animation_finished(anim_name: String) -> void:
	# 如果是 dash 动画结束，调用 dash 回调
	if anim_name == "冲刺" and dash_finished_callback.is_valid():
		dash_finished_callback.call()
		dash_finished_callback = Callable()
	
## 旋转方向
func turn_direction() -> void:
	var velocity:Vector2 = owner.velocity
	if velocity.x != 0:
		sprite.scale.x = -1 if velocity.x < 0 else 1

## 是否在地上
func is_on_floor() -> bool:
	return owner.is_on_floor()
