class_name BuildingInstance
extends RefCounted

var definition: BuildingDef
var tier_index: int = 0
var employment: int = 0

func _init(building_definition: BuildingDef, initial_tier: int = 0) -> void:
	definition = building_definition
	tier_index = initial_tier

func tier() -> Dictionary:
	return definition.tiers[tier_index]
