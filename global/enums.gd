extends Node

enum ETickGroup {
	InputTick,
	BeforeMovement,
	Movement,
	AfterMovement,
	BeforeGameplay,
	GamePlay,
	AfterGameplay,
	BeforePhysics,
	Physics,
	AfterPhysics
}

enum CapabilityTags {
	Idle,
	Move,
	MoveAnimation,
	Dash,
	Jump,
	Hurt,
	RegenHp,
	RegenMp,
	NotStartTiming
}
