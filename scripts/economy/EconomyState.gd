class_name EconomyState
extends RefCounted

var tick_count: int = 0
var stockpile: Dictionary = {}
var population: Dictionary = {"farmer": 0, "worker": 0, "unemployed": 100}
var terrain_counts: Dictionary = {"farm": 20, "coast": 10, "forest": 10, "vein": 5}
var buildings: Array[BuildingInstance] = []
var subsistence_employment: int = 0
var logs: Array[String] = []
var last_tick_summary: String = ""

func _init() -> void:
	stockpile = {"grain": 200, "meat": 50, "fish": 20, "wood": 100, "iron": 50, "coal": 50, "sulfur": 30, "tools": 50, "fertilizer": 20, "steel": 20, "ship": 5, "advanced_tools": 10, "advanced_fertilizer": 0, "construction_power": 0}

func add_log(message: String) -> void:
	logs.append("[틱 %d] %s" % [tick_count, message])

func buildings_farm_count() -> int:
	var count := 0
	for instance in buildings:
		if instance.definition.terrain == "farm": count += 1
	return count

func total_population() -> int:
	return int(population.farmer + population.worker + population.unemployed)

func snapshot() -> Dictionary:
	return {"tick": tick_count, "stockpile": stockpile.duplicate(), "population": population.duplicate(), "logs": logs.duplicate()}
