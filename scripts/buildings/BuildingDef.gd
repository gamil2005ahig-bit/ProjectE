class_name BuildingDef
extends Resource

var id: String
var name_kr: String
var terrain: String
var labor_type: String
var capacity: int
var tiers: Array[Dictionary]
var build_cost: int
var build_unable: bool
var category: String

func setup(def_id: String, display_name: String, terrain_id: String, labor: String, worker_capacity: int, tier_data: Array[Dictionary], cost: int, unable: bool, building_category: String) -> BuildingDef:
	id = def_id
	name_kr = display_name
	terrain = terrain_id
	labor_type = labor
	capacity = worker_capacity
	tiers = tier_data
	build_cost = cost
	build_unable = unable
	category = building_category
	return self
