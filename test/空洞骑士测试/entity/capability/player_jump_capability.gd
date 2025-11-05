extends BaseCapability
class_name PlayerJumpCapability

var body : CharacterBody2D

func on_active():
	body = owner as CharacterBody2D

func tick_active(delta):
	var velocity = body.velocity
	if Input.is_action_just_pressed("jump"):
		if !body.is_on_floor(): return
		velocity.y = -component.jump_speed
	if velocity.y < 0 and !Input.is_action_pressed("jump"):
		# 长按跳：不追加额外上升期重力；松开则追加额外重力以实现短跳
		velocity.y += component.jump_higher * delta * component.gravity
	velocity.y += component.gravity * delta
	body.velocity.y = velocity.y
