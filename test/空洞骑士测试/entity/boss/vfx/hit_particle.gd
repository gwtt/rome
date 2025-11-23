extends CPUParticles2D

func _ready() -> void:
	emitting = true
	await finished
	call_deferred("queue_free")
