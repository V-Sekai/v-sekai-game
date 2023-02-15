extends GutTest

## Test visual novel planner


var domain_name = "romantic"

var the_domain = preload("res://addons/task_goal/core/domain.gd").new(domain_name)

var planner = preload("res://addons/task_goal/core/plan.gd").new()

func travel_location(state, entity, location):
	state.at[entity] = location
	state.world['time'] = state.world['time'] + 1
	return state
		
func m_travel_location(state, entity, location):
	if entity in state.entities and location in state.locations and state.at[entity] != location:
		return [['travel_location', entity, location]]
	return false

func practice_piano(state, variable, value):
	state.world['angry_at_repertoire'] = true
	state.world['time'] = state.world['time'] + 1
	return state
		
func m_practice_piano(state, variable, value):
	if variable in state.world and variable == "angry_at_repertoire":
		return [['practice_piano', null, null]]
	return false


func bar_concert_night(state, variable, value):
	state.world['concert_tonight'] = true
	state.world['time'] = state.world['time'] + 1
	return state


func m_bar_concert_night(state, variable, value):
	if variable in state.world and variable == "day" and (state.world["day"] % 7 == 1 or state.world["day"] % 7 == 2):
		return [['bar_concert_night', null, null]]
	return false

#
#func increment_time(state):
#	state.world['time'] = state.world['time'] + 1
#	return state
#
#func increment_time(state):
#	var future_time: int = state.world["day"] % 7 + state.world["day"]
#	print(future_time)
#	var travel: Array = []
#	for i in range(future_time):
#		travel.push_back(["m_time_travel_to_concert_night", state.world["time"], future_time + i])
#	var random_actions: Array = state.actions
#	random_actions.shuffle()
#	for action in random_actions:
#		if action == "travel_location":
#			var random_entities: Array = state.entities
#			random_entities.shuffle()
#			var random_locations: Array = state.locations
#			random_locations.shuffle()
#			return [[action, random_entities.front(), random_locations.front()], ["increment_time"]] + travel
#		return [[action, null, null], ["increment_time"]] + travel
#	return false
#
#func m_time_travel_to_concert_night(state: Dictionary, variable: String, value: Variant) -> Variant:
#	if variable in state.world and variable == "day" and (state.world["day"] % 7 == 1 or state.world["day"] % 7 == 2):
#		return [['bar_concert_night', null, null]]
#	return false

func prepare_for_concert(state: Dictionary) -> Variant:
	state.world["band_problems"] = true
	state.world["concert_tonight"] = true
	return state

func m_prepare_for_concert(state: Dictionary, variable: String, value: Variant) -> Variant:
	if variable in state.world and variable == "concert_tonight" and value == false:
		return [["prepare_for_concert"]]
	return false

func seb_met_person(state: Dictionary, person: String) -> Variant:
	state.seb_met["mia"] = true
	return state
	
func has_entity_met_entity(state: Dictionary, e_1:String, e_2, place: String) -> Variant:
	return [Multigoal.new("entities_together", {"at": {e_1: place, e_2: place}})]
	
	
func trigger_goal(state: Dictionary, ideal_state, goal: Array) -> Variant:
	var result: Variant = planner.find_plan(ideal_state, [goal])
	if result is Array:
		return result
	return []


var state1 : Dictionary
var novel_goal: Multigoal = Multigoal.new("novel_goal", 
	{"world": {"met_mia": true, "concert_tonight": true, "band_problems": true, 'mia_girlfriend': false}})


func before_each():
	state1.clear()
	planner._domains.push_back(the_domain)

	# If we've changed to some other domain, this will change us back.
	planner.current_domain = the_domain
	planner.declare_actions([
			Callable(self, "travel_location"),
			Callable(self, "practice_piano"),
			Callable(self, "prepare_for_concert"),
			Callable(self, "meet_person"),
			Callable(self, "seb_met_person"),
		]
	)
	planner.declare_task_methods("entity_met_entity",
		[
			Callable(self, "has_entity_met_entity"),
		])
	planner.declare_task_methods("trigger_goal",
		[
			Callable(self, "trigger_goal"),
		])
	planner.declare_unigoal_methods('at', [Callable(self, "m_travel_location")])
	planner.declare_unigoal_methods('world', [Callable(self, "m_practice_piano")])
	planner.declare_unigoal_methods('world', [Callable(self, "m_prepare_for_concert")])
	planner.declare_unigoal_methods('seb_met', [Callable(self, "m_has_seb_met_person")])
	planner.declare_multigoal_methods([planner.m_split_multigoal])
	planner.print_domain()
	
	state1.locations = ['coffee_shop', 'home', 'groceries', 'bar', 'sports', 'club']
	state1.entities = ['seb', 'mia', 'jazz']
	state1.unigoal_methods = planner.current_domain._unigoal_method_dict.keys()
	
	state1.at = {'seb': 'home', 'mia': 'groceries', 'jazz': 'groceries'}
	
	state1.seb_met = {'mia': false}
	
	state1.world = {
		'angry_at_repertoire': false,
		'concert_tonight': false,
		'band_problems': false,
		'mia_girlfriend': false,
		'photo_shoot_on_day_4': false,
		'time': 0,
		'day': 0,
		'night': false,
	}

func test_move_to_home():
	planner.verbose = 1
	var plan = planner.find_plan(state1.duplicate(true), [['at', 'seb', 'coffee_shop']])
	assert_eq(plan, [["travel_location", "seb", "coffee_shop"]], "")


func test_move_to_band_practice():
	planner.verbose = 1
	var plan = planner.find_plan(state1.duplicate(true), [['at', 'seb', 'bar']])
	assert_eq(plan,  [["travel_location", "seb", "bar"]], "")


func test_practice_piano():
	planner.verbose = 1
	var plan = planner.find_plan(state1.duplicate(true), [['world', 'angry_at_repertoire', true]])
	assert_eq(plan,  [["practice_piano", null, null]], "")


func test_together_goal():
	planner.verbose = 1
	var plan = planner.find_plan(state1.duplicate(true), [["entity_met_entity", "seb", "mia", "coffee_shop"]])
	assert_eq(plan, [["travel_location", "seb", "coffee_shop"], ["travel_location", "mia", "coffee_shop"]], "")


func test_trigger_goal():
	planner.verbose = 1
	var plan = planner.find_plan(state1.duplicate(true), [["trigger_goal", state1.duplicate(true), [ "at", "seb", "coffee_shop"]]])
	assert_eq(plan,  [["travel_location", "seb", "coffee_shop"]], "")


func test_trigger_goal_empty():
	planner.verbose = 2
	var plan = planner.find_plan(state1.duplicate(true), [["trigger_goal", state1.duplicate(true), [ "world", "mia_girlfriend", true]]])
	assert_eq(plan, [], "")


#func test_novel_goal():
#	planner.verbose = 1
#	planner.find_plan(state1.duplicate(true), [novel_goal])
#
