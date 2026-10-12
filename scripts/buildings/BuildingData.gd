class_name BuildingData
extends RefCounted

const RESOURCE_NAMES := {"grain":"곡물", "meat":"고기", "fish":"생선", "wood":"나무", "iron":"철", "coal":"석탄", "sulfur":"유황", "steel":"강철", "ship":"배", "tools":"공구", "advanced_tools":"고급 공구", "fertilizer":"비료", "advanced_fertilizer":"고급 비료", "construction_power":"건설력"}
const TERRAIN_NAMES := {"farm":"농지", "coast":"해안", "forest":"숲", "vein":"광맥", "any":"제한 없음"}
const LABOR_NAMES := {"farmer":"농민", "worker":"노동자"}

static func tier(inputs: Dictionary, outputs: Dictionary) -> Dictionary:
	return {"input": inputs, "output": outputs}

static func make(id: String, name: String, terrain: String, labor: String, capacity: int, tiers: Array[Dictionary], cost: int, unable := false, category := "factory") -> BuildingDef:
	return BuildingDef.new().setup(id, name, terrain, labor, capacity, tiers, cost, unable, category)

static func all() -> Array[BuildingDef]:
	return [
		# "만원 생산"은 농민 10명 완전 고용 시 곡물 10, 고기 2, 나무 1의 최대 생산이며 고용 비율에 따라 비례한다.
		make("subsistence_farm", "자경 농장", "farm", "farmer", 10, [tier({}, {"grain":10, "meat":2, "wood":1})], 0, true, "primary"),
		make("farm", "농장", "farm", "worker", 5, [tier({}, {"grain":20}), tier({"fertilizer":10}, {"grain":50}), tier({"fertilizer":10, "advanced_fertilizer":10}, {"grain":200})], 50, false, "primary"),
		make("ranch", "가축 목장", "farm", "worker", 5, [tier({}, {"meat":20}), tier({"tools":10}, {"meat":40}), tier({"tools":10, "advanced_tools":10}, {"meat":200})], 50, false, "primary"),
		make("fishing_dock", "어업 부두", "coast", "worker", 5, [tier({}, {"fish":20}), tier({"ship":5}, {"fish":40}), tier({"ship":5, "advanced_tools":5}, {"fish":200})], 50, false, "primary"),
		make("lumber_mill", "벌목장", "forest", "worker", 5, [tier({}, {"wood":40}), tier({"tools":10}, {"wood":80}), tier({"advanced_tools":5}, {"wood":160})], 50, false, "primary"),
		make("iron_mine", "철 광산", "vein", "worker", 10, [tier({"tools":10}, {"iron":20}), tier({"tools":10, "coal":10}, {"iron":40}), tier({"advanced_tools":5, "coal":10}, {"iron":80})], 100, false, "mine"),
		make("coal_mine", "석탄 광산", "vein", "worker", 10, [tier({"tools":10}, {"coal":40}), tier({"tools":20}, {"coal":80}), tier({"advanced_tools":10}, {"coal":160})], 100, false, "mine"),
		make("sulfur_mine", "유황 광산", "vein", "worker", 10, [tier({"tools":10}, {"sulfur":20}), tier({"tools":10, "coal":10}, {"sulfur":40}), tier({"advanced_tools":5, "coal":10}, {"sulfur":80})], 100, false, "mine"),
		make("tool_workshop", "공구 작업장", "any", "worker", 20, [tier({"wood":40}, {"tools":20}), tier({"iron":20, "wood":20}, {"tools":40}), tier({"steel":20}, {"tools":100})], 200),
		make("fertilizer_factory", "비료 공장", "any", "worker", 20, [tier({"wood":20}, {"fertilizer":10}), tier({"sulfur":20, "coal":10}, {"fertilizer":40}), tier({"sulfur":20, "coal":10, "advanced_tools":10}, {"fertilizer":40, "advanced_fertilizer":40})], 200),
		make("advanced_tool_workshop", "고급 공구 작업장", "any", "worker", 25, [tier({"steel":20, "wood":20}, {"advanced_tools":20}), tier({"steel":40, "tools":10}, {"advanced_tools":50}), tier({"steel":40}, {"advanced_tools":80})], 250),
		make("steel_mill", "제강소", "any", "worker", 50, [tier({"iron":40, "coal":20}, {"steel":20}), tier({"iron":40, "coal":40}, {"steel":40}), tier({"iron":80, "coal":40}, {"steel":80})], 500),
		make("shipyard", "조선소", "any", "worker", 50, [tier({"wood":80}, {"ship":20}), tier({"iron":40, "wood":40}, {"ship":40}), tier({"steel":20, "iron":20, "wood":20}, {"ship":80})], 500),
		make("construction_sector", "건설 부문", "any", "worker", 2, [tier({"wood":20}, {"construction_power":1}), tier({"wood":20, "tools":10}, {"construction_power":3}), tier({"iron":20, "wood":10, "tools":5}, {"construction_power":10}), tier({"steel":10, "advanced_tools":5, "wood":10}, {"construction_power":30})], 20)
	]

static func by_id() -> Dictionary:
	var result := {}
	for definition in all():
		result[definition.id] = definition
	return result
