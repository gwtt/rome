extends Resource
class_name PlayerData

@export var soul := 0:
	set(value):
		if value >= 9:
			value = 9
		
		if value <= 0:
			value = 0
		
		soul = value
		changed.emit()
		
@export var health := 45:
	set(value):
		if value >= 45:
			value = 45
			
		if value <= 0:
			value = 0	
		health = value
		changed.emit()
	get():
		return health

