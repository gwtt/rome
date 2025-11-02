@tool
extends EditorPlugin

const DEBUG_SYSTEM: StringName = &"DebugSystem"
const SAVE_SYSTEM: StringName = &"SaveSystem"

func _enable_plugin() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/debug_system.gd")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)

func _enter_tree() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/debug_system.gd")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")

func _exit_tree() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)
