class_name TickEngine
extends RefCounted

var state: EconomyState
var definitions: Dictionary

func _init(economy_state: EconomyState, building_definitions: Dictionary) -> void:
	state = economy_state
	definitions = building_definitions

# Tick order: labor allocation -> placed production -> one virtual farm -> living consumption -> population change -> UI refresh.
func run_tick() -> void:
	PopulationModel.allocate_labor(state, definitions)
	state.add_log("노동 자동 배치 완료")
	for instance in state.buildings:
		_produce(instance)
	_produce_subsistence()
	var consumption := PopulationModel.consume_living(state)
	state.add_log("생활 소비: 곡물 %.0f, 고기 %.1f, 생선 %.1f" % [consumption.grain_used, consumption.meat_used, consumption.fish_used])
	var population_log := PopulationModel.apply_population_delta(state, consumption)
	state.add_log(population_log)
	state.last_tick_summary = population_log
	state.tick_count += 1

func _produce(instance: BuildingInstance) -> void:
	var tier: Dictionary = instance.tier()
	_produce_values(instance.definition.name_kr, instance.employment, instance.definition.capacity, tier)

func _produce_subsistence() -> void:
	var empty_farm_slots := max(0, int(state.terrain_counts.get("farm", 0)) - state.buildings_farm_count())
	var aggregate_capacity := empty_farm_slots * 10
	var employment := min(aggregate_capacity, state.subsistence_employment)
	if not definitions.has("subsistence_farm"):
		return
	var definition: BuildingDef = definitions["subsistence_farm"]
	_produce_values(definition.name_kr, employment, aggregate_capacity, definition.tiers[0])

func _produce_values(name: String, employment: int, capacity: int, tier: Dictionary) -> void:
	if employment <= 0 or capacity <= 0:
		return
	var input_ratio := 1.0
	for resource in tier.input:
		var need := float(tier.input[resource])
		if need <= 0.0:
			continue
		input_ratio = min(input_ratio, float(state.stockpile.get(resource, 0.0)) / need)
	input_ratio = clamp(input_ratio, 0.0, 1.0)
	var employment_ratio := clamp(float(employment) / float(capacity), 0.0, 1.0)
	var effective_ratio := input_ratio * employment_ratio
	if input_ratio < 1.0:
		EconomyLogger.shortage(state, name, input_ratio)
	for resource in tier.input:
		state.stockpile[resource] = float(state.stockpile.get(resource, 0.0)) - effective_ratio * float(tier.input[resource])
	for resource in tier.output:
		state.stockpile[resource] = float(state.stockpile.get(resource, 0.0)) + effective_ratio * float(tier.output[resource])
