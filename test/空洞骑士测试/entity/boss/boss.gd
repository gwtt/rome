extends CharacterBody2D

@export var noise_emitter: PhantomCameraNoiseEmitter2D
@export var audio_system: Node
@export var boss_stat_component: BossStatsComponent
@export var hrif_hit_box_area: CollisionPolygon2D
@export var gravity := 1000

var player:Player
var was_facing_right := false
var is_facing_right := false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("空洞骑士")
	boss_stat_component.player = player

func _physics_process(_delta: float) -> void:
	self.move_and_slide()

## 旋转方向
func turn_direction() -> void:
	if boss_stat_component.player:
		## 如果玩家位置在Boss左边
		var direction = 1 if boss_stat_component.player.global_position.x < self.global_position.x else -1
		if direction == 1:
			was_facing_right = false
		else:
			was_facing_right = true
		if is_facing_right != was_facing_right:
			is_facing_right = was_facing_right
			self.scale.x = abs(self.scale.x) * -1
		boss_stat_component.direction_x = -direction

func add_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func shake_camera(amplitude: float) -> void:
	noise_emitter.get_noise().amplitude = amplitude
	noise_emitter.emit()

func stop_time(time_scale: float) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(0.03).timeout
	Engine.time_scale = 1
