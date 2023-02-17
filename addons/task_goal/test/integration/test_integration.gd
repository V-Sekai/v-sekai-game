extends GutTest

## Test visual novel planner

var domain_name = "romantic"

var the_domain = preload("res://addons/task_goal/core/domain.gd").new(domain_name)

var planner = preload("res://addons/task_goal/core/plan.gd").new()


func travel_location(state, entity, location):
	state.at[entity] = location
	return state


func m_travel_location(state, entity, location):
	if entity in state.entities and location in state.locations and state.at[entity] != location:
		return [["travel_location", entity, location]]
	return false


func has_entity_met_entity(state: Dictionary, e_1: String, e_2, place: String) -> Variant:
	return [Multigoal.new("entities_together", {"at": {e_1: place, e_2: place}})]


var state1: Dictionary


func before_each():
	planner._domains.push_back(the_domain)

	# If we've changed to some other domain, this will change us back.
	planner.current_domain = the_domain
	(
		planner
		. declare_actions(
			[
				Callable(self, "travel_location"),
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

	planner.declare_unigoal_methods("at", [Callable(self, "m_travel_location")])
	planner.declare_multigoal_methods([planner.m_split_multigoal])
	planner.print_domain()

	state1.locations = ["coffee_shop", "home", "groceries"]
	state1.entities = ["seb", "mia"]

	state1.at = {"seb": "home", "mia": "groceries"}


func test_together_goal():
	var plan = planner.find_plan(state1.duplicate(true), [["entity_met_entity", "seb", "mia", "coffee_shop"]])
	assert_eq(plan, [["travel_location", "seb", "coffee_shop"], ["travel_location", "mia", "coffee_shop"]], "")
