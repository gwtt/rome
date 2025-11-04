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
	Hurt,
	RegenHp,
	RegenMp,
	NotStartTiming
}
