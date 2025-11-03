## 专门用于保存&读取
extends Node

var archive: String = "Archive"
var system: String = "System"

#region 存储
'''以下为保存功能实现'''
const config_path := "user://settings.cfg" # 配置文件
const override_path := "user://override.cfg" # 配置文件
var file := ConfigFile.new()
var system_file := ConfigFile.new()

func _ready() -> void:
	# 初始化读取配置
	var err := file.load(config_path)
	if err != OK:
		DebugSystem.printWarning("文件加载失败：%d" % err, self)

## 是否存在该配置
func has_config(section: String, key: String) -> bool:
	return file.has_section_key(section, key)

## 配置加载[br]
## section：一级分组，如“系统设置”
## key：二级分组，如“翻译”
## value：保存的值，如“中文”
func save_config(section: String, key: String, value: Variant) -> void:
	file.set_value(section, key, value)
	var err := file.save(config_path)
	if err != OK:
		DebugSystem.printError("文件保存失败：%d" % err, self)

## 配置保存
func load_config(section: String, key: String, default: Variant) -> Variant:
	var err := file.load(config_path)
	if err != OK:
		DebugSystem.printDebug("文件加载失败：%d" % err, self)
		return file.get_value(section, key, default)
	else:
		return file.get_value(section, key, default)

## 系统配置保存
func seve_system_config(section: String, key: String, value: Variant) -> void:
	system_file.set_value(section, key, value)
	var err := system_file.save(override_path)
	if err != OK:
		DebugSystem.printError("文件保存失败：%d" % err, self)

## 系统配置加载
func load_system_config(section: String, key: String, value: Variant) -> Variant:
	var err := system_file.save(override_path)
	if err != OK:
		DebugSystem.printWarning("文件加载失败：%d" % err, self)
		return system_file.get_value(section, key, value)
	else:
		return system_file.get_value(section, key, value)

## 清除指定小节配置
func erase_section(section: String) -> void:
	if file.has_section(section):
		file.erase_section(section)
		var err := file.save(config_path)
		if err != OK:
			DebugSystem.printError("文件保存失败：%d" % err, self)
	else:
		DebugSystem.printError("不存在该 section：%s" % section, self)

## 彻底配置清除
func config_clear() -> void:
	file.clear()
	file.save(config_path)

## 彻底系统配置清除
func system_config_clear() -> void:
	system_file.clear()
	system_file.save(config_path)
#endregion
