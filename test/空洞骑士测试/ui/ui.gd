extends CanvasLayer

@onready var soul: TextureRect = $Soul
@onready var health: TextureRect = $Health

@export var player_data: PlayerData

var soul_dic = {
	0: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽01.png",
	1: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽02.png",
	2: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽03.png",
	3: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽04.png",
	4: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽05.png",
	5: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽06.png",
	6: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽07.png",
	7: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽08.png",
	8: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽09.png",
	9: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/灵魂槽10.png"
}
var health_dic = {
	0: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条01.png",
	1: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条02.png",
	2: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条03.png",
	3: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条04.png",
	4: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条05.png",
	5: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条06.png",
	6: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条07.png",
	7: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条08.png",
	8: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条09.png",
	9: "res://test/空洞骑士测试/空洞骑士教程素材（更新2025.10.20）/ui/血条10.png"
}

func _ready() -> void:
	player_data.changed.connect(on_changed)
	player_data.changed.emit()

func on_changed() -> void:
	soul.texture = load(soul_dic[player_data.soul])
	health.texture = load(health_dic[player_data.health / 5])
