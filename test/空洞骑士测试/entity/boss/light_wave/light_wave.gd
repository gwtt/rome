extends CharacterBody2D

var direction = 1: 
	set(value):
		direction = value
		turn_direction(value)
		
const SPEED = 400.0

func turn_direction(value) -> void:
	self.scale.x = -value

func _physics_process(_delta: float) -> void:
	velocity.x = SPEED * direction
	move_and_slide()
