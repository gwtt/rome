extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	EventBugSystem.subscribe("boss_start", on_boss_start)
	EventBugSystem.subscribe("boss_end", on_boss_end)
	
func open() -> void:
	animation_player.play("open")
	
func close() -> void:
	animation_player.play("close")

func on_boss_start() -> void:
	close()

func on_boss_end() -> void:
	open()
