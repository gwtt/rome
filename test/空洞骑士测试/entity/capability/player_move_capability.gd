extends BaseCapability
class_name PlayerMoveCapability

var body : CharacterBody2D 

func on_active():
	body = owner as CharacterBody2D

func tick_active(delta):
	var move_vector = Input.get_action_strength("moveRight") - Input.get_action_strength("moveLeft")
	var velocity := body.velocity
	velocity.x = move_vector * component.accelerate_speed * delta
	velocity.x = clamp(velocity.x, -component.max_speed, component.max_speed)
	if move_vector == 0:
		velocity.x = lerp(0.0, velocity.x, pow(2, -50 * delta))
	body.velocity.x = velocity.x
	body.move_and_slide()
