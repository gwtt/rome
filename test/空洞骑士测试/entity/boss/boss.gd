extends CharacterBody2D

@export var boss_stat_component: BossStatsComponent
@export var hrif_hit_box_area: CollisionPolygon2D
var player:Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("空洞骑士")
	boss_stat_component.player = player

func _physics_process(_delta: float) -> void:
	self.move_and_slide()
