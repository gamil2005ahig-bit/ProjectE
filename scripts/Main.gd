extends Control

var state: EconomyState
var engine: TickEngine
var definitions: Dictionary
@onready var tick_button: Button = $Layout/TickButton
@onready var metrics: Label = $Layout/Metrics
@onready var stockpile_label: Label = $Layout/Stockpile
@onready var terrain_label: Label = $Layout/Terrain
@onready var buildings_label: Label = $Layout/Buildings
@onready var build_select: OptionButton = $Layout/BuildPanel/BuildSelect
@onready var build_details: Label = $Layout/BuildPanel/BuildDetails
@onready var build_button: Button = $Layout/BuildPanel/BuildButton
@onready var build_status: Label = $Layout/BuildPanel/BuildStatus
@onready var log_view: RichTextLabel = $Layout/LogScroll/Log

func _ready() -> void:
	definitions = BuildingData.by_id()
	state = EconomyState.new()
	for id in ["farm", "farm", "ranch", "lumber_mill", "fishing_dock"]:
		state.buildings.append(BuildingInstance.new(definitions[id]))
	engine = TickEngine.new(state, definitions)
	tick_button.pressed.connect(_on_tick_pressed)
	build_select.item_selected.connect(_on_build_selection_changed)
	build_button.pressed.connect(_on_build_pressed)
	_populate_build_options()
	_refresh()
	print("ProjectE ready: tick=0 pop=100")

func _populate_build_options() -> void:
	var default_index := 0
	for definition in BuildingData.all():
		var index := build_select.item_count
		build_select.add_item(definition.name_kr)
		build_select.set_item_metadata(index, definition.id)
		build_select.set_item_disabled(index, definition.build_unable)
		if not definition.build_unable and default_index == 0:
			default_index = index
	build_select.select(default_index)

func _on_tick_pressed() -> void:
	engine.run_tick()
	_refresh()
	print("TICK %d pop=%d grain=%d meat=%d fish=%d log_tail=%s" % [state.tick_count, state.total_population(), int(state.stockpile.grain), int(state.stockpile.meat), int(state.stockpile.fish), state.logs[-1]])

func _on_build_selection_changed(_index: int) -> void:
	_refresh_build_panel()

func _on_build_pressed() -> void:
	var definition := _selected_definition()
	var reason := _build_error(definition)
	if reason != "건설 가능":
		_refresh_build_panel()
		return
	state.stockpile["construction_power"] = float(state.stockpile.get("construction_power", 0.0)) - definition.build_cost
	state.buildings.append(BuildingInstance.new(definition))
	state.add_log("%s 건설 완료: 건설력 %d" % [definition.name_kr, definition.build_cost])
	_refresh()

func _selected_definition() -> BuildingDef:
	if build_select.selected < 0:
		return null
	var id := str(build_select.get_item_metadata(build_select.selected))
	return definitions.get(id)

func _build_error(definition: BuildingDef) -> String:
	if definition == null:
		return "건설할 건물을 선택하세요."
	if definition.build_unable:
		return "건설 불가"
	if definition.terrain != "any":
		if not state.terrain_counts.has(definition.terrain) or int(state.terrain_counts[definition.terrain]) <= 0:
			return "지형 불일치: 필요한 지형이 없습니다."
		var used_slots := _building_count_on_terrain(definition.terrain)
		if used_slots >= int(state.terrain_counts[definition.terrain]):
			return "사용 가능한 %s 슬롯이 없습니다." % BuildingData.TERRAIN_NAMES[definition.terrain]
	if float(state.stockpile.get("construction_power", 0.0)) < definition.build_cost:
		return "건설력 부족: 필요 %d, 보유 %.0f" % [definition.build_cost, float(state.stockpile.get("construction_power", 0.0))]
	return "건설 가능"

func _building_count_on_terrain(terrain: String) -> int:
	var count := 0
	for instance in state.buildings:
		if instance.definition.terrain == terrain:
			count += 1
	return count

func _refresh() -> void:
	metrics.text = "현재 틱: %d    전체 인구: %d    농민: %d    노동자: %d    무직: %d" % [state.tick_count, state.total_population(), state.population.farmer, state.population.worker, state.population.unemployed]
	var stock_text := "재고\n"
	for resource in BuildingData.RESOURCE_NAMES:
		stock_text += "%s: %.1f    " % [BuildingData.RESOURCE_NAMES[resource], float(state.stockpile.get(resource, 0.0))]
	stockpile_label.text = stock_text
	terrain_label.text = "지형 슬롯: 농지 %d | 해안 %d | 숲 %d | 광맥 %d" % [state.terrain_counts.farm, state.terrain_counts.coast, state.terrain_counts.forest, state.terrain_counts.vein]
	var building_text := "건물 목록\n건물명                 단계       고용·정원     지형\n"
	for instance in state.buildings:
		building_text += "%s    %d단계    %d/%d       %s\n" % [instance.definition.name_kr, instance.tier_index + 1, instance.employment, instance.definition.capacity, BuildingData.TERRAIN_NAMES[instance.definition.terrain]]
	var farm_capacity := max(0, int(state.terrain_counts.farm) - state.buildings_farm_count()) * 10
	building_text += "자경 농장             1단계    %d/%d       농지 (건설 불가)" % [state.subsistence_employment, farm_capacity]
	buildings_label.text = building_text
	log_view.text = "\n".join(state.logs)
	_refresh_build_panel()

func _refresh_build_panel() -> void:
	var definition := _selected_definition()
	if definition == null:
		build_details.text = "비용: -\n필요 지형: -"
		build_button.disabled = true
		build_status.text = "건설할 건물을 선택하세요."
		return
	var terrain_name: String = BuildingData.TERRAIN_NAMES[definition.terrain]
	build_details.text = "비용: 건설력 %d\n필요 지형: %s" % [definition.build_cost, terrain_name]
	var reason := _build_error(definition)
	build_button.disabled = reason != "건설 가능"
	build_status.text = reason
