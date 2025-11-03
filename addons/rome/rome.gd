@tool
extends EditorPlugin

const DEBUG_SYSTEM: StringName = &"DebugSystem"
const SAVE_SYSTEM: StringName = &"SaveSystem"
const GLOBAL_SYSTEM: StringName = &"GlobalSystem"
const AUDIO_SYSTEM: StringName = &"AudioSystem"

func _enable_plugin() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/debug_system.gd")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")
	if not Engine.has_singleton(GLOBAL_SYSTEM):
		add_autoload_singleton(GLOBAL_SYSTEM, "res://addons/rome/system/global_system.gd")
	if not Engine.has_singleton(AUDIO_SYSTEM):
		add_autoload_singleton(AUDIO_SYSTEM, "res://addons/rome/system/tscn/audio_system.tscn")

func _disable_plugin() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)
	remove_autoload_singleton(GLOBAL_SYSTEM)
	remove_autoload_singleton(AUDIO_SYSTEM)

func _enter_tree() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/debug_system.gd")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")
	if not Engine.has_singleton(GLOBAL_SYSTEM):
		add_autoload_singleton(GLOBAL_SYSTEM, "res://addons/rome/system/global_system.gd")
	if not Engine.has_singleton(AUDIO_SYSTEM):
		add_autoload_singleton(AUDIO_SYSTEM, "res://addons/rome/system/tscn/audio_system.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)
	remove_autoload_singleton(GLOBAL_SYSTEM)
	remove_autoload_singleton(AUDIO_SYSTEM)
