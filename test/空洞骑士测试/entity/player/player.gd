extends CharacterBody2D
class_name Player

@onready var player_stats_component: PlayerStatsComponent = $PlayerStatsComponent

@onready var hurt_box_area: Area2D = $HurtBoxArea
@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Sprite2D = $Sprite2D

var was_facing_right := false
var is_facing_right := false

func _physics_process(_delta: float) -> void:
	move_and_slide()

## 旋转方向
func turn_direction() -> void:
	## 受伤要方向颠倒
	var direction = player_stats_component.direction_x
	if direction == 1:
		was_facing_right = false
	else:
		was_facing_right = true
	if is_facing_right != was_facing_right:
		is_facing_right = was_facing_right
		self.scale.x = abs(self.scale.x) * -1
		
func add_gravity(delta: float) -> void:
	self.velocity.y += player_stats_component.gravity * delta
