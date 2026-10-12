class_name EconomyLogger
extends RefCounted

static func add(state: EconomyState, message: String) -> void:
	state.add_log(message)

static func shortage(state: EconomyState, building_name: String, ratio: float) -> void:
	add(state, "%s 입력 부족 (%.0f%%)" % [building_name, ratio * 100.0])
