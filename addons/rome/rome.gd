@tool
extends EditorPlugin

const DEBUG_SYSTEM: StringName = &"DebugSystem"
const SAVE_SYSTEM: StringName = &"SaveSystem"
const GLOBAL_SYSTEM: StringName = &"GlobalSystem"
const AUDIO_SYSTEM: StringName = &"AudioSystem"
const EVENT_BUG_SYSTEM: StringName = &"EventBugSystem"

#const CAPABILITY_SYSTEM: StringName = &"CapabilitySystem"
func _enable_plugin() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/tscn/debug_system.tscn")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")
	if not Engine.has_singleton(GLOBAL_SYSTEM):
		add_autoload_singleton(GLOBAL_SYSTEM, "res://addons/rome/system/global_system.gd")
	if not Engine.has_singleton(AUDIO_SYSTEM):
		add_autoload_singleton(AUDIO_SYSTEM, "res://addons/rome/system/tscn/audio_system.tscn")	
	if not Engine.has_singleton(EVENT_BUG_SYSTEM):
		add_autoload_singleton(EVENT_BUG_SYSTEM, "res://addons/rome/utils/event_bus_system.gd")
	
	#if not Engine.has_singleton(CAPABILITY_SYSTEM):
		#add_autoload_singleton(CAPABILITY_SYSTEM, "res://addons/rome/capabilities/capability_system.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)
	remove_autoload_singleton(GLOBAL_SYSTEM)
	remove_autoload_singleton(AUDIO_SYSTEM)
	remove_autoload_singleton(EVENT_BUG_SYSTEM)
	
	#remove_autoload_singleton(CAPABILITY_SYSTEM)
func _enter_tree() -> void:
	if not Engine.has_singleton(DEBUG_SYSTEM):
		add_autoload_singleton(DEBUG_SYSTEM, "res://addons/rome/system/tscn/debug_system.tscn")
	if not Engine.has_singleton(SAVE_SYSTEM):
		add_autoload_singleton(SAVE_SYSTEM, "res://addons/rome/system/save_system.gd")
	if not Engine.has_singleton(GLOBAL_SYSTEM):
		add_autoload_singleton(GLOBAL_SYSTEM, "res://addons/rome/system/global_system.gd")
	if not Engine.has_singleton(AUDIO_SYSTEM):
		add_autoload_singleton(AUDIO_SYSTEM, "res://addons/rome/system/tscn/audio_system.tscn")
	if not Engine.has_singleton(EVENT_BUG_SYSTEM):
		add_autoload_singleton(EVENT_BUG_SYSTEM, "res://addons/rome/utils/event_bus_system.gd")
	#if not Engine.has_singleton(CAPABILITY_SYSTEM):
		#add_autoload_singleton(CAPABILITY_SYSTEM, "res://addons/rome/capabilities/capability_system.gd")

func _exit_tree() -> void:
	remove_autoload_singleton(DEBUG_SYSTEM)
	remove_autoload_singleton(SAVE_SYSTEM)
	remove_autoload_singleton(GLOBAL_SYSTEM)
	remove_autoload_singleton(AUDIO_SYSTEM)
	remove_autoload_singleton(EVENT_BUG_SYSTEM)
	#remove_autoload_singleton(CAPABILITY_SYSTEM)
