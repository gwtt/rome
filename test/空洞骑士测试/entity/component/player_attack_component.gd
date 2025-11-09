extends Node

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

var finished_callback := Callable()
var current_anim_name:String = ''

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)

## 播放动画
func play_anim(anim_name: String, _callback: Callable = Callable()) -> void:
	if !animation_player.has_animation(anim_name) and current_anim_name != anim_name:
		DebugSystem.printWarning("玩家角色无动画:" + anim_name)
		return
	animation_player.play(anim_name)
	current_anim_name = anim_name
	finished_callback = _callback
	
## 动画播放结束回调
func _on_animation_finished(_anim_name: String) -> void:
	current_anim_name = ''	
	if finished_callback.is_valid():
		finished_callback.call()
		finished_callback = Callable()


