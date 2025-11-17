extends Resource
class_name BossData

@export var health := 1000:
	set(value):
		if value <= 0:
			value = 0
		health = value
		changed.emit()
	get():
		return health
