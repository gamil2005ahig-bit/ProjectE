class_name PopulationModel
extends RefCounted

const LABOR_ORDER := ["primary", "mine", "factory"]

static func allocate_labor(state: EconomyState, _definitions: Dictionary) -> void:
	var farmer_pool := max(0, int(state.population.get("farmer", 0)))
	var worker_pool := max(0, int(state.population.get("worker", 0)))
	var unemployed_pool := max(0, int(state.population.get("unemployed", 0)))
	var assigned_farmers := 0
	var assigned_workers := 0

	for instance in state.buildings:
		instance.employment = 0
	for category in LABOR_ORDER:
		for instance in state.buildings:
			if instance.definition.category != category:
				continue
			var remaining := instance.definition.capacity
			if instance.definition.labor_type == "farmer":
				var from_farmers := min(remaining, farmer_pool)
				farmer_pool -= from_farmers
				remaining -= from_farmers
				var from_unemployed := min(remaining, unemployed_pool)
				unemployed_pool -= from_unemployed
				instance.employment = from_farmers + from_unemployed
				assigned_farmers += instance.employment
			elif instance.definition.labor_type == "worker":
				var from_workers := min(remaining, worker_pool)
				worker_pool -= from_workers
				remaining -= from_workers
				var from_unemployed := min(remaining, unemployed_pool)
				unemployed_pool -= from_unemployed
				instance.employment = from_workers + from_unemployed
				assigned_workers += instance.employment

	var empty_farm_slots := max(0, int(state.terrain_counts.get("farm", 0)) - state.buildings_farm_count())
	var subsistence_capacity := empty_farm_slots * 10
	var subsistence_from_farmers := min(subsistence_capacity, farmer_pool)
	farmer_pool -= subsistence_from_farmers
	var subsistence_from_unemployed := min(subsistence_capacity - subsistence_from_farmers, unemployed_pool)
	unemployed_pool -= subsistence_from_unemployed
	var subsistence_employment := subsistence_from_farmers + subsistence_from_unemployed
	assigned_farmers += subsistence_employment

	state.subsistence_employment = subsistence_employment
	state.population.farmer = assigned_farmers + farmer_pool
	state.population.worker = assigned_workers + worker_pool
	state.population.unemployed = unemployed_pool

static func consume_living(state: EconomyState) -> Dictionary:
	var total := state.total_population()
	var grain_need := float(total)
	var grain_before := float(state.stockpile.grain)
	var grain_used := min(grain_before, grain_need)
	state.stockpile.grain -= grain_used
	var food_need := total / 5.0
	var meat_before := float(state.stockpile.meat)
	var fish_before := float(state.stockpile.fish)
	var combined := meat_before + fish_before
	var meat_used := 0.0
	var fish_used := 0.0
	if combined > 0.0:
		meat_used = min(meat_before, food_need * meat_before / combined)
		fish_used = min(fish_before, food_need - meat_used)
	state.stockpile.meat -= meat_used
	state.stockpile.fish -= fish_used
	return {"grain_shortfall": max(0.0, grain_need - grain_before), "grain_used": grain_used, "meat_used": meat_used, "fish_used": fish_used}

static func apply_population_delta(state: EconomyState, consumption: Dictionary) -> String:
	var shortfall := float(consumption.grain_shortfall)
	if shortfall > 0.0:
		var loss := max(1, int(floor(shortfall / 10.0)))
		for group in ["unemployed", "worker", "farmer"]:
			var removed := min(loss, int(state.population[group]))
			state.population[group] -= removed
			loss -= removed
			if loss == 0:
				break
		return "곡물 부족으로 인구 감소"
	var growth := int(floor(min(float(state.stockpile.grain), (float(state.stockpile.meat) + float(state.stockpile.fish)) * 5.0) / 10.0))
	state.population.unemployed += growth
	return "인구 증가: %d명" % growth
