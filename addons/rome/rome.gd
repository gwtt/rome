@tool
extends EditorPlugin

const SAVE_SYSTEM: StringName = "save_system"

func _enable_plugin() -> void:
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(SAVE_SYSTEM)

func _enter_tree() -> void:
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")

func _exit_tree() -> void:
	remove_autoload_singleton(SAVE_SYSTEM)
