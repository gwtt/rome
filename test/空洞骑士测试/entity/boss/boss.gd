extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(_delta: float) -> void:
	animation_player.play("站立")
