## 自动加载
## 每帧用来展示一系列的变量更新情况，需要监控一个变量需要添加它到watchList属性里面

extends Node

#region Parameters

## 设置debug级别的信息在log中的可见性
## NOTE: 不会影响普通日志
@export var shouldPrintDebugLogs: bool = OS.is_debug_build() # TBD：为了提升性能，这应该是一个常量吗？


## 设置调试信息覆盖文本以及[member watchList]的可见性。
## 注意：不会影响框架警告标签的可见性。
@export var showDebugLabels: bool = OS.is_debug_build():
	set(newValue):
		showDebugLabels = newValue
		self.set_process(showDebugLabels) # 性能：不需要时不要每帧更新

## 运行时监控的变量[Dictionary]。键是其他节点的变量或属性名称。
## 更新现有键的值将更新该属性的标签，即在运行时显示其值。
## 示例：`Debug.watchList.velocity = characterBody.velocity`
## 注意：清空列表不会导致[member watchListLabel]被清空，因为当[member watchList]为空时，每帧[method _process]会被跳过。
## 警告：替换变量值中的"["和"]"以避免BBCode注入！像"[color]"或"[url]"这样的标签可能会破坏整个[member watchListLabel]，甚至可能是恶意的！
## `watchList[value].replace("[", "[lb]")`
@export var watchList: Dictionary[StringName, Variant] = {}

## 影响某些调用点如[method Tools.addChildAndSetOwner]的[method Node.add_child]的`force_readable_name`参数。
## 如果为`true`，运行时动态添加的每个子节点将有一个独特的"可读"名称来辅助调试等。
## 警告：性能：根据Godot文档，`force_readable_name`可能"非常慢"。
@export var shouldForceReadableName: bool = OS.is_debug_build()

const customLogMaximumEntries: int = 100

#endregion


#region State

#@onready var debugWindow:	 Window = %DebugWindow
#@onready var logWindow:		 Window = %CustomLogWindow
#
#@onready var labels:		 Node   = %Labels
#@onready var label:			 Label  = %Label
#@onready var warningLabel:	 Label  = %WarningLabel
#@onready var watchListLabel: RichTextLabel  = %WatchListLabel # TBD：性能：我们应该坚持使用普通的[Label]吗？还是在调试时性能无关紧要？
#@onready var customLogList:	 Container = %CustomLogList
#
#@onready var debugBackground: Node2D = %DebugBackground

var previousChartWindowInitialPosition: Vector2i

static var lastFrameLogged:		 int  = -1 # 从-1开始，这样第一个帧0才能被打印。
static var isTraceLogAlternateRow: bool = false ## 被[method printTrace]用于交替行背景等以提高清晰度。
static var customLogColorFlag:	 bool

## 一个自定义日志，为每个组件及其父实体等保存额外按需信息。
## @experimental
static var customLog:			Array[Dictionary]

static var testMode:			bool ## 被[TestMode].gd设置，供其他脚本使用，用于临时游戏玩法测试。

#endregion


#region Logging

func printLog(message: String = "", object: Variant = null, messageColor: String = "", objectColor: String = "") -> void:
	updateLastFrameLogged()
	print_rich(str("[color=", objectColor, "]", object, "[/color] [color=", messageColor, "]", message)) # [/color] 不必要


## 为AutoLoad脚本打印日志消息，不使用任何状态变量，如当前帧。
## 在框架完全准备就绪之前记录条目很有用。
func printAutoLoadLog(message: String = "") -> void:
	var caller: String = get_stack()[1].source.get_file().trim_suffix(".gd")
	print_rich(str("[color=ORANGE]", caller, "[/color] ", message))


## 打印淡化消息以减少视觉混乱。
## 受[member shouldPrintDebugLogs]影响
func printDebug(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	#updateLastFrameLogged() # 省略：不要在单独一行打印帧，以减少混乱。
	#print_debug(str(Engine.get_frames_drawn()) + " " + message) # 省略：没用，因为总是会显示是从这个Debug脚本调用的。
	print_rich(str("[right][color=dimgray]F", Engine.get_frames_drawn(), " ", object, " ", message)) # [/color] 不必要


## 在输出日志和Godot调试器控制台中打印警告消息。
## 提示：要查看导致警告的最近函数调用链，请使用[method Debug.printTrace]
func printWarning(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var callerOfLogger: String = " ← " + getCaller(3) # 获取堆栈索引3，这是调用调用这个打印函数的函数的函数 :)
	push_warning(str("⚠️ ", object, " ", message, callerOfLogger)) # push_warning()不会在输出日志中添加行，所以我们可以自己添加颜色格式化的消息。
	print_rich(str("[indent]⚠️[color=yellow]", object, " ", message, "[color=orange]", callerOfLogger)) # [/color] 不必要


## 在输出日志和Godot调试器控制台中打印错误消息。包括调用者的文件和方法。
## 注意：在发布版本中，如果[member Settings.shouldAlertOnError]为true，会显示一个阻止引擎执行的OS警报。
## 提示：要查看导致错误的最近函数调用链，请使用[method Debug.printTrace]
func printError(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	updateLastFrameLogged()
	var plainText: String = str("❗️ ", object, " ", message, " ← ", getCaller(3)) # 获取堆栈索引3，这是调用调用这个打印函数的函数的函数 :)
	push_error(plainText)
	printerr(plainText)
	# 不要打印重复行，以减少混乱。
	#print_rich("[indent]❗️ [color=red]" + objectName + " " + message) # [/color] 不必要

	# 警告：如果不是在编辑器中开发，错误时崩溃。
	if not OS.is_debug_build():
		OS.alert(message, "Framework Error")


## 用粗体和鲜艳颜色打印消息，两侧有空行。
## 有助于在调试控制台中快速找到重要消息。
func printHighlight(message: String = "", object: Variant = null, _objectColor: String = "") -> void:
	print_rich(str("\n[indent]>[b][color=white]", object, " ", message, "\n")) # [/color][/b] 不必要


## 用高亮颜色打印变量数组。
## 受[member shouldPrintDebugLogs]影响
func printVariables(values: Array[Variant], separator: String = "\t ", color: String = "orange") -> void:
	if shouldPrintDebugLogs:
		print_rich(str("[color=", color, "][b]", separator.join(values)))


## 记录并返回一个显示变量之前和之后值的字符串，如果有变化且[member shouldPrintDebugLogs]为true
## 提示：[param logAsTrace]列出最近的函数调用以帮助跟踪是什么导致变量发生变化。
## 受[member shouldPrintDebugLogs]影响
func printChange(variableName: String, previousValue: Variant, newValue: Variant, logAsTrace: bool = false) -> String:
	# TODO：可选的图表？:)
	if shouldPrintDebugLogs and previousValue != newValue:
		var difference: String
		if (newValue is int or newValue is float) and (previousValue is int or previousValue is float):
			difference = " (%+f" % (newValue - previousValue) + ")"
		var string: String = str(previousValue, " → ", newValue, difference) # TBD：在previousValue之后写差值？
		if not logAsTrace: printLog(string, variableName, "dimgray", "gray")
		else: printTrace([string], variableName, 3)
		return string
	else:
		return ""


## 用高亮颜色打印变量数组，以及在调用日志方法之前3个最近函数及其文件名的"堆栈跟踪"。
## 提示：有助于快速/临时调试当前关注的bug。
## 注意：不受[member shouldPrintDebugLogs]影响，但只在调试版本中运行时才打印。
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
			# 抱歉：这个混乱的代码而不是简单的`separator.join(values)`是为了在值之间交替颜色以提高可读性
			# 性能：注意任何FPS影响！:')
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


## 打印漂亮的堆栈转储，包括所有子节点和变量。
func printStackDump(object: Variant, includeChildNodes: bool = true, includeLocalVariables: bool = true, includeMemberVariables: bool = false, includeGlobalVariables: bool = false) -> void:
	const globalVariableColor:	String = "[color=dimgray]"
	const memberVariableColor:	String = "[color=dimgray]"
	const localVariableColor:	String = "[color=gray]"
	const backgroundColor:		String = "[bgcolor=201030]"
	var stack: Array[ScriptBacktrace]  = Engine.capture_script_backtraces(includeGlobalVariables or includeMemberVariables or includeLocalVariables)

	print_rich(str("\n\n", backgroundColor, "[color=orange]↦ [b]STACK DUMP[/b] @ Rendering Frame:", Engine.get_frames_drawn(), " Time:", float(Time.get_ticks_msec()) / 1000),
	"\n\t[color=cyan][b]", object, "[/b] ← ", object.get_parent() if object is Node else null)

	if includeChildNodes and object is Node:
		print_rich(str("\t[color=lightblue]", object.get_children(true))) # 包含内部节点

	var backtrace: ScriptBacktrace
	for backtraceIndex in stack.size():
		backtrace = stack[backtraceIndex]
		if stack.size() > 1: print(str("Backtrace ", backtraceIndex))

		# 函数调用

		if includeGlobalVariables:
			for globalVariableIndex in backtrace.get_global_variable_count():
				print_rich(str(globalVariableColor, "\t[b]", backtrace.get_global_variable_name(globalVariableIndex), "[/b]:\t", backtrace.get_global_variable_value(globalVariableIndex)))

		# 函数调用

		print_rich("\t[color=dimgray]0: 日志记录函数")

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


## 返回一个表示调用堆栈中指定[param stackPosition]的脚本文件和函数名称的字符串。
## 默认值：2，即调用这个方法的调用者的函数。
## 示例：如果`Component.gd`中的`_ready()`调用[method Debug.printError]，然后`printError()`调用`getCaller()`，那么`get_stack()[2]`就是`Component.gd:_ready()`
## [0]是`getCaller()`本身，[1]将是`printError()`等等。
## 如果位置大于堆栈大小，返回"?"。
## 注意：不包含函数参数。
static func getCaller(stackPosition: int = 2) -> String:
	if stackPosition > get_stack().size() - 1: return "?" # TBD：返回空字符串还是什么？
	var caller: Dictionary = get_stack()[stackPosition] # 检查：获取调用者的调用者（想要记录的函数 → 日志函数 → 这个函数）
	return caller.source.get_file() + ":" + caller.function + "()"


## 更新帧计数器，并在不同帧的日志之间打印额外行以提高可读性。
static func updateLastFrameLogged() -> void:
	if not lastFrameLogged == Engine.get_frames_drawn():
		lastFrameLogged = Engine.get_frames_drawn()
		print_rich(str("\n[right][u][b]Frame ", lastFrameLogged, "[/b] ", float(Time.get_ticks_msec()) / 1000))

#endregion


#region Custom Log UI

class CustomLogKeys:
	# 注意：必须全部小写以供`Tools.setLabelsWithDictionary()`使用
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

	# 除非对象指定了自定义父级（如组件提到其实体），否则只获取场景中的父节点
	if parent: customLogEntry[CustomLogKeys.parent] = parent
	elif object is Node: customLogEntry[CustomLogKeys.parent] = object.get_parent()

	customLogEntry[CustomLogKeys.message] = message

## 返回一个包含对象几乎所有详细信息的字典，使用[Debug.CustomLogKeys]
static func getObjectDetails(object: Variant) -> Dictionary[StringName, Variant]:
	# TBD：值应该是实际变量还是字符串？

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
