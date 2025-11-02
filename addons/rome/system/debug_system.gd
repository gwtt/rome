## AutoLoad
## Displays a list of variables updated per frame. To watch a variable, add it to the `watchList` property

extends Node


#region Parameters

## Sets the visibility of "debug"-level messages in the log.
## NOTE: Does NOT affect normal logging.
@export var shouldPrintDebugLogs: bool = OS.is_debug_build() # TBD: Should this be a constant to improve performance?

## Sets the visibility of the debug information overlay text, as well as the [member watchList].
## NOTE: Does NOT affect the visibility of the framework warning label.
@export var showDebugLabels: bool = OS.is_debug_build():
	set(newValue):
		showDebugLabels = newValue
		self.set_process(showDebugLabels) # PERFORMANCE: Don't update per-frame if not needed

## A [Dictionary] of variables to monitor at runtime. The keys are the names of the variables or properties from other nodes.
## Updating the value of an existing key will update the label for that property i.e. to show its value at runtime.
## EXAMPLE: `Debug.watchList.velocity = characterBody.velocity`
## NOTE: Clearing the list will not cause [member watchListLabel] to be cleared because the per-frame [method _process] is skipped when [member watchList] is empty.
## ALERT: Replace "[" & "]" in variable values to avoid BBCode injection! Tags like "[color]" or "[url]" may wonk the entire [member watchListLabel] and may even be intentionally malicious!
## `watchList[value].replace("[", "[lb]")`
@export var watchList: Dictionary[StringName, Variant] = {}

## Affects the `force_readable_name` parameter of [method Node.add_child] at some call sites such as [method Tools.addChildAndSetOwner].
## If `true`, each child node added dynamically at runtime will have a unique and "readable" name to aid debugging etc.
## WARNING: PERFORMANCE: `force_readable_name` may be "very slow" according to Godot documentation.
@export var shouldForceReadableName: bool = OS.is_debug_build()

const customLogMaximumEntries: int = 100

#endregion


#region State

@onready var debugWindow:	 Window = %DebugWindow
@onready var logWindow:		 Window = %CustomLogWindow

@onready var labels:		 Node   = %Labels
@onready var label:			 Label  = %Label
@onready var warningLabel:	 Label  = %WarningLabel
@onready var watchListLabel: RichTextLabel  = %WatchListLabel # TBD: PERFORMANCE: Should we stick to a regular [Label]? or performance doesn't matter anyway while debugging?
@onready var customLogList:	 Container = %CustomLogList

@onready var debugBackground: Node2D = %DebugBackground

var previousChartWindowInitialPosition: Vector2i

static var lastFrameLogged:		 int  = -1 # Start at -1 so the first frame 0 can be printed.
static var isTraceLogAlternateRow: bool = false ## Used by [method printTrace] to alternate the row background etc. for clarity.
static var customLogColorFlag:	 bool

## A custom log that holds extra on-demand information for each component and its parent entity etc.
## @experimental
static var customLog:			Array[Dictionary]

static var testMode:			bool ## Set by [TestMode].gd for use by other scripts, for temporary gameplay testing.

#endregion


#region Logging

func printLog(message: String = "", object: Variant = null, messageColor: String = "", objectColor: String = "") -> void:
	updateLastFrameLogged()
	print_rich(str("[color=", objectColor, "]", object, "[/color] [color=", messageColor, "]", message)) # [/color] not necessary


## Prints a log message for an AutoLoad script without using any state variables such as the current frame.
## Useful for logging entries before the framework is completely ready.
func printAutoLoadLog(message: String = "") -> void:
	var caller: String = get_stack()[1].source.get_file().trim_suffix(".gd")
	print_rich(str("[color=ORANGE]", caller, "[/color] ", message))


## Prints a faded message to reduce visual clutter.
## Affected by [member shouldPrintDebugLogs]
func printDebug(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	#updateLastFrameLogged() # OMIT: Do not print frames on a separate line, to reduce clutter.
	#print_debug(str(Engine.get_frames_drawn()) + " " + message) # OMIT: Not useful because it will always say it was called from this Debug script.
	print_rich(str("[right][color=dimgray]F", Engine.get_frames_drawn(), " ", object, " ", message)) # [/color] not necessary


## Prints a warning message in the Output Log and Godot Debugger Console.
## TIP: To see the chain of recent function calls which led to a warning, use [method Debug.printTrace]
func printWarning(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var callerOfLogger: String = " ← " + getCaller(3) # Get the stack index 3 for the function that called the function which called this print function :)
	push_warning(str("⚠️ ", object, " ", message, callerOfLogger)) # push_warning() does not add a line to the output log, so we can add a color-formatted message ourselves.
	print_rich(str("[indent]􀇿 [color=yellow]", object, " ", message, "[color=orange]", callerOfLogger)) # [/color] not necessary


## Prints an error message in the Output Log and Godot Debugger Console. Includes the caller's file and method.
## NOTE: In release builds, if [member Settings.shouldAlertOnError] is true, displays an OS alert which blocks engine execution.
## TIP: To see the chain of recent function calls which led to an error, use [method Debug.printTrace]
func printError(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var plainText: String = str("❗️ ", object, " ", message, " ← ", getCaller(3)) # Get the stack index 3 for the function that called the function which called this print function :)
	push_error(plainText)
	printerr(plainText)
	# Don't print a duplicate line, to reduce clutter.
	#print_rich("[indent]❗️ [color=red]" + objectName + " " + message) # [/color] not necessary

	# WARNING: Crash on error if not developing in the editor.
	if not OS.is_debug_build():
		OS.alert(message, "Framework Error")


## Prints the message in bold and a bright color, with empty lines on each side.
## Helpful for finding important messages quickly in the debug console.
func printHighlight(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	print_rich(str("\n[indent]􀢒 [b][color=white]", object, " ", message, "\n")) # [/color][/b] not necessary


## Prints an array of variables in a highlighted color.
## Affected by [member shouldPrintDebugLogs]
func printVariables(values: Array[Variant], separator: String = "\t ", color: String = "orange") -> void:
	if shouldPrintDebugLogs:
		print_rich(str("[color=", color, "][b]", separator.join(values)))


## Logs and returns a string showing a variable's previous and new values, IF there is a change and [member shouldPrintDebugLogs]
## TIP: [param logAsTrace] lists recent function calls to assist in tracking what caused the variable to change.
## Affected by [member shouldPrintDebugLogs]
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsTrace: bool = false) -> String:
	# TODO: Optional charting? :)
	if shouldPrintDebugLogs and previousValue != newValue:
		var difference: String
		if (newValue is int or newValue is float) and (previousValue is int or previousValue is float):
			difference = " (%+f" % (newValue - previousValue) + ")"
		var string: String = str(previousValue, " → ", newValue, difference) # TBD: Write difference after previousValue?
		if not logAsTrace: printLog(string, variableName, "dimgray", "gray")
		else: printTrace([string], variableName, 3)
		return string
	else:
		return ""


## Prints an array of variables in a highlighted color, along with a "stack trace" of the 3 most recent functions and their filenames before the log method was called.
## TIP: Helpful for quick/temporary debugging of bugs currently under attention.
## NOTE: NOT affected by [member shouldPrintDebugLogs] but only prints if running in a debug build.
func printTrace(values: Array[Variant] = [], object: Variant = null, stackPosition: int = 2, separator: String = " [color=dimgray]•[/color] ") -> void:
	if OS.is_debug_build():
		const textColorA1: String = "[color=FF80FF]"
		const textColorA2: String = "[color=C060C0]"
		const textColorB1: String = "[color=8080FF]"
		const textColorB2: String = "[color=6060C0]"

		var textColor1:	   String = textColorA1 if not isTraceLogAlternateRow else textColorB1
		var textColor2:    String = textColorA2 if not isTraceLogAlternateRow else textColorB2

		var backgroundColor: String = "[bgcolor=101020]" if not isTraceLogAlternateRow else "[bgcolor=001030]"
		var bullet: String = " ⬦ " if not isTraceLogAlternateRow else " ⬥ "

		print_rich(str(backgroundColor, textColor1, bullet, "F", Engine.get_frames_drawn(), " ", float(Time.get_ticks_msec()) / 1000, " [b]", object if object else "", "[/b] @ ", getCaller(stackPosition), textColor2, " ← ", getCaller(stackPosition+1), " ← ", getCaller(stackPosition+2)))

		if not values.is_empty():
			# SORRY: This mess instead of just `separator.join(values)` is so we can alternate color between values for better readability
			# PERFORMANCE: Watch out for any FPS impact! :')
			var joinedValues: String = ""
			var isAlternateValueColor: bool
			var valueColor: String
			for value: Variant in values:
				if not isTraceLogAlternateRow: valueColor = textColorA1 if not isAlternateValueColor else textColorA2
				else: valueColor = textColorB1 if not isAlternateValueColor else textColorB2
				joinedValues += str(valueColor, value, separator)
				isAlternateValueColor = not isAlternateValueColor
			print_rich(str(backgroundColor, " 　 ", joinedValues.trim_suffix(separator)))
		isTraceLogAlternateRow = not isTraceLogAlternateRow


## Prints a pretty stack dump, including all child nodes and variables.
func printStackDump(object: Variant, includeChildNodes: bool = true, includeLocalVariables: bool = true, includeMemberVariables: bool = false, includeGlobalVariables: bool = false) -> void:
	const globalVariableColor:	String = "[color=dimgray]"
	const memberVariableColor:	String = "[color=dimgray]"
	const localVariableColor:	String = "[color=gray]"
	const backgroundColor:		String = "[bgcolor=201030]"
	var stack: Array[ScriptBacktrace]  = Engine.capture_script_backtraces(includeGlobalVariables or includeMemberVariables or includeLocalVariables)

	print_rich(str("\n\n", backgroundColor, "[color=orange]↦ [b]STACK DUMP[/b] @ Rendering Frame:", Engine.get_frames_drawn(), " Time:", float(Time.get_ticks_msec()) / 1000),
	"\n\t[color=cyan][b]", object, "[/b] ← ", object.get_parent() if object is Node else null)

	if includeChildNodes and object is Node:
		print_rich(str("\t[color=lightblue]", object.get_children(true))) # include_internal

	var backtrace: ScriptBacktrace
	for backtraceIndex in stack.size():
		backtrace = stack[backtraceIndex]
		if stack.size() > 1: print(str("Backtrace ", backtraceIndex))

		if includeGlobalVariables:
			for globalVariableIndex in backtrace.get_global_variable_count():
				print_rich(str(globalVariableColor, "\t[b]", backtrace.get_global_variable_name(globalVariableIndex), "[/b]:\t", backtrace.get_global_variable_value(globalVariableIndex)))

		# The function calls

		print_rich("\t[color=dimgray]0: The logging function")

		var topColor: String
		for frameIndex in backtrace.get_frame_count():
			if frameIndex == 0: continue # Skip this logging function
			topColor = "[color=FF80FF]" if frameIndex == 1 else "[color=white]"

			print_rich(str("\t", frameIndex, ": ", topColor, backtrace.get_frame_file(frameIndex), " [b]", backtrace.get_frame_function(frameIndex), "[/b]()[/color]\t Line:", backtrace.get_frame_line(frameIndex)))

			if includeLocalVariables:
				for localVariableIndex in backtrace.get_local_variable_count(frameIndex):
					print_rich(str(localVariableColor, "\t\t[b]", backtrace.get_local_variable_name(frameIndex, localVariableIndex), "[/b]:\t", backtrace.get_local_variable_value(frameIndex, localVariableIndex)))

			if includeMemberVariables:
				for memberVariableIndex in backtrace.get_member_variable_count(frameIndex):
					print_rich(str(memberVariableColor, "\t\t[b]", backtrace.get_member_variable_name(frameIndex, memberVariableIndex), "[/b]:\t", backtrace.get_member_variable_value(frameIndex, memberVariableIndex)))


## Returns a string denoting the script file & function name from the specified [param stackPosition] on the call stack.
## Default: 2 which is the function that called the CALLER of this method.
## Example: If `_ready()` in `Component.gd` calls [method Debug.printError], then `printError()` calls `getCaller()`, then `get_stack()[2]` is `Component.gd:_ready()`
## [0] is `getCaller()` itself, [1] would be `printError()` and so on.
## If the position is larger than the stack, a "?" is returned.
## NOTE: Does NOT include function arguments.
static func getCaller(stackPosition: int = 2) -> String:
	if stackPosition > get_stack().size() - 1: return "?" # TBD: Return an empty string or what?
	var caller: Dictionary = get_stack()[stackPosition] # CHECK: Get the caller of the caller (function that wants to log → log function → this function)
	return caller.source.get_file() + ":" + caller.function + "()"


## Updates the frame counter and prints an extra line between logs from different frames for clarity of readability.
static func updateLastFrameLogged() -> void:
	if not lastFrameLogged == Engine.get_frames_drawn():
		lastFrameLogged = Engine.get_frames_drawn()
		print_rich(str("\n[right][u][b]Frame ", lastFrameLogged, "[/b] ", float(Time.get_ticks_msec()) / 1000))

#endregion


#region Custom Log UI

class CustomLogKeys:
	# NOTE: Must be all lower case for `Tools.setLabelsWithDictionary()`
	const message	= &"message"
	const frameTime	= &"frametime"
	const object	= &"object"
	const instance	= &"instance"
	const name		= &"name"
	const type		= &"type"
	const nodeClass	= &"nodeclass"
	const baseScript = &"basescript"
	const className	= &"classname"
	const parent	= &"parent"


## @experimental
func addCustomLog(object: Variant, parent: Variant, message: String) -> void:
	var customLogEntry: Dictionary[StringName, Variant] = getObjectDetails(object)

	# Unless the object specified a custom parent, like a Component mentioning its Entity, just get the parent Node in the scene
	if parent: customLogEntry[CustomLogKeys.parent] = parent
	elif object is Node: customLogEntry[CustomLogKeys.parent] = object.get_parent()

	customLogEntry[CustomLogKeys.message] = message

## Returns a dictionary of almost all details about an object, using the [Debug.CustomLogKeys]
static func getObjectDetails(object: Variant) -> Dictionary[StringName, Variant]:
	# TBD: Should the values be actual variables or Strings?

	var dictionary: Dictionary[StringName, Variant] = {
		CustomLogKeys.frameTime:	str("F", Engine.get_frames_drawn(), " ", float(Time.get_ticks_msec()) / 1000),
		CustomLogKeys.object:		object,
		CustomLogKeys.instance:		object.get_instance_id(),
		CustomLogKeys.name:			object.name,
		CustomLogKeys.type:			type_string(typeof(object)),
		CustomLogKeys.nodeClass:	object.get_class()
	}

	var script: Script = object.get_script()

	if script:
		dictionary[CustomLogKeys.className] = script.get_global_name()

		var baseScript: Script = script.get_base_script()
		if baseScript:  dictionary[CustomLogKeys.baseScript] = baseScript.get_global_name()

	return dictionary

#endregion
