extends BaseComponent
class_name BossStatsComponent

@export var state_chart:StateChart
@export var player: Player

## 正数为右边，负数为左边
var direction_x
## 是否是下戳
var is_punch_down
