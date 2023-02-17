extends GutTest

## Test visual novel planner

var domain_name = "romantic"

var the_domain = preload("res://addons/task_goal/core/domain.gd").new(domain_name)

var planner = preload("res://addons/task_goal/core/plan.gd").new()


func travel_location(state, entity, location):
	state.at[entity] = location
	state.world["time"] = state.world["time"] + 1
	return state


func m_travel_location(state, entity, location):
	if entity in state.entities and location in state.locations and state.at[entity] != location:
		return [["travel_location", entity, location]]
	return false


func practice_piano(state):
	state.world["angry_at_repertoire"] = true
	state.world["time"] = state.world["time"] + 1
	return state


func m_practice_piano(state, variable, value):
	if variable in state.world and state.world["angry_at_repertoire"] == false:
		return [["practice_piano"]]
	return false


func bar_concert_night(state, variable, value):
	state.world["concert_tonight"] = true
	state.world["time"] = state.world["time"] + 1
	return state


func m_bar_concert_night(state, variable, value):
	if variable in state.world and variable == "day" and (state.world["day"] % 7 == 1 or state.world["day"] % 7 == 2):
		return [["bar_concert_night", null, null]]
	return false


func prepare_for_concert(state: Dictionary) -> Variant:
	state.world["band_problems"] = true
	state.world["concert_tonight"] = true
	return state


func m_prepare_for_concert(state: Dictionary, variable: String, value: Variant) -> Variant:
	if variable in state.world and variable == "concert_tonight" and value == false:
		return [["prepare_for_concert"]]
	return false


func seb_met_mia(state: Dictionary) -> Variant:
	state.world["met_mia"] = true
	state.world["mia_girlfriend"] = true
	return state


func has_entity_met_entity(state: Dictionary, e_1: String, e_2, place: String) -> Variant:
	return [Multigoal.new("entities_together", {"at": {e_1: place, e_2: place}})]


func seb_travel_bar(state: Dictionary) -> Variant:
	return [["at", "seb", "bar"]]


func m_met_mia(state: Dictionary, variable: String, value: Variant) -> Variant:
	if variable in state.world and variable == "met_mia" and state.world["met_mia"] == false:
		return [
			Multigoal.new("entities_together", {"at": {"seb": "coffee_shop", "mia": "coffee_shop"}}), ["seb_met_mia"]
		]
	return false


func m_play_game(state):
	return [Multigoal.new("mia_girlfriend", {"world": {"met_mia": true, "mia_girlfriend": true}})]


var state1: Dictionary


func before_each():
	state1.clear()
	planner._domains.push_back(the_domain)

	# If we've changed to some other domain, this will change us back.
	planner.current_domain = the_domain
	(
		planner
		. declare_actions(
			[
				Callable(self, "travel_location"),
				Callable(self, "practice_piano"),
				Callable(self, "prepare_for_concert"),
				Callable(self, "meet_person"),
				Callable(self, "seb_met_mia"),
				Callable(self, "mia_girlfriend"),
				Callable(self, "time_travel"),
			]
		)
	)
	(
		planner
		. declare_task_methods(
			"entity_met_entity",
			[
				Callable(self, "has_entity_met_entity"),
			]
		)
	)
	(
		planner
		. declare_task_methods(
			"seb_travel_bar",
			[
				Callable(self, "seb_travel_bar"),
			]
		)
	)
	(
		planner
		. declare_task_methods(
			"play_game",
			[
				Callable(self, "m_play_game"),
			]
		)
	)

	planner.declare_unigoal_methods("at", [Callable(self, "m_travel_location")])
	planner.declare_unigoal_methods("world", [Callable(self, "m_met_mia")])
	planner.declare_multigoal_methods([planner.m_split_multigoal])
	planner.print_domain()

	state1.locations = ["coffee_shop", "home", "groceries", "bar", "sports", "club"]
	state1.entities = ["seb", "mia", "jazz"]
	state1.unigoal_methods = [
		"seb_meet_mia",
	]

	state1.at = {"seb": "home", "mia": "groceries", "jazz": "groceries"}

	state1.world = {
		"angry_at_repertoire": false,
		"concert_tonight": false,
		"band_problems": false,
		"met_mia": false,
		"mia_girlfriend": false,
		"photo_shoot_on_day_4": false,
		"time": 0,
		"day": 0,
		"night": false,
	}


func test_move_to_home():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "seb", "coffee_shop"]])
	assert_eq(plan, [["travel_location", "seb", "coffee_shop"]], "")


func test_move_to_band_practice():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "seb", "bar"]])
	assert_eq(plan, [["travel_location", "seb", "bar"]], "")


func test_together_goal():
	var plan = planner.find_plan(state1.duplicate(true), [["entity_met_entity", "seb", "mia", "coffee_shop"]])
	assert_eq(plan, [["travel_location", "seb", "coffee_shop"], ["travel_location", "mia", "coffee_shop"]], "")


func test_play_game():
	var plan = planner.find_plan(state1.duplicate(true), [["play_game"]])
	assert_eq(
		plan,
		[["travel_location", "seb", "coffee_shop"], ["travel_location", "mia", "coffee_shop"], ["seb_met_mia"]],
		""
	)
