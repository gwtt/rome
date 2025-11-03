extends Node
## 测试debug_system的功能

var test_counter: int = 0
var test_string: String = "初始值"

func _ready() -> void:
	test_debug()

func test_debug() -> void:
	DebugSystem.printHighlight("=== 开始调试系统功能测试 ===", self, "red")

	# 1. printLog - 普通日志
	DebugSystem.printLog("这是普通日志", "TestObject", "blue", "green")

	# 2. printAutoLoadLog - 自动加载日志
	DebugSystem.printAutoLoadLog("这是自动加载日志")

	# 3. printDebug - 调试信息
	DebugSystem.printDebug("这是一个调试信息", "DebugSystem", "")

	# 4. printWarning - 警告信息
	DebugSystem.printWarning("这是一个警告信息", "WarningObject", "")

	# 5. printError - 错误信息
	DebugSystem.printError("这是一个错误信息", "ErrorObject", "")

	# 6. printHighlight - 高亮信息
	DebugSystem.printHighlight("这是一个高亮信息", "HighlightObject", "")

	# 7. printVariables - 变量数组打印
	var test_array = ["苹果", "香蕉", "橙子", 123, 456.789]
	DebugSystem.printVariables(test_array, " | ", "yellow")

	# 8. printChange - 变量变化跟踪
	var old_value = test_counter
	test_counter = 42
	DebugSystem.printChange("test_counter", old_value, test_counter)

	var old_string = test_string
	test_string = "新值"
	DebugSystem.printChange("test_string", old_string, test_string, true)  # 使用trace模式

	# 9. printTrace - 堆栈跟踪
	DebugSystem.printTrace(["参数1", "参数2", 123], "TraceObject", 2)

	# 10. printStackDump - 堆栈转储
	DebugSystem.printStackDump(self, true, true, false, false)

	# 11. addCustomLog - 自定义日志
	DebugSystem.addCustomLog(self, get_tree().root, "这是一个自定义日志条目")

	# 12. 测试 watchList 功能（如果启用）
	if DebugSystem.shouldPrintDebugLogs:
		DebugSystem.watchList["test_counter"] = test_counter
		DebugSystem.watchList["test_string"] = test_string
		DebugSystem.watchList["test_node"] = self

	DebugSystem.printHighlight("=== 调试系统功能测试完成 ===", self)

	# 测试完成后的清理
	DebugSystem.watchList.clear()
