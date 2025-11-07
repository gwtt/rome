extends Node
class_name PlayerAttackComponent

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer


## 播放动画
func play_anim(anim_name: String, _callback: Callable = Callable()) -> void:
	if !animation_player.has_animation(anim_name):
		DebugSystem.printWarning("玩家角色无动画:" + anim_name)
		return
	animation_player.play(anim_name)



