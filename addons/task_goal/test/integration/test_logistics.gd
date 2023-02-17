extends GutTest

#This file is based on the logistics-domain examples included with HGNpyhop:
#	https://github.com/ospur/hgn-pyhop
#For a discussion of the adaptations that were needed, see the relevant
#section of Some_GTPyhop_Details.md in the top-level directory.
#-- Dana Nau <nau@umd.edu>, July 20, 2021

var domain_name = "logistics"

var the_domain = preload("res://addons/task_goal/core/domain.gd").new(domain_name)

var planner = preload("res://addons/task_goal/core/plan.gd").new()

## Actions

func drive_truck(state, t, l):
	state.truck_at[t] = l
	return state


func load_truck(state, o, t):
	state.at[o] = t
	return state


func unload_truck(state, o, l):
	var t = state.at[o]
	if state.truck_at[t] == l:
		state.at[o] = l
		return state


func fly_plane(state, plane, a):
	state.plane_at[plane] = a
	return state


func load_plane(state, o, plane):
	state.at[o] = plane
	return state


func unload_plane(state, o, a):
	var plane = state.at[o]
	if state.plane_at[plane] == a:
		state.at[o] = a
		return state


## Helper functions for the methods


# Find a truck in the same city as the package
func find_truck(state, o):
	for t in state.trucks:
		if state.in_city[state.truck_at[t]] == state.in_city[state.at[o]]:
			return t
	return false


# Find a plane in the same city as the package; if none available, find a random plane
func find_plane(state, o):
	var random_plane
	for plane in state.airplanes:
		if state.in_city[state.plane_at[plane]] == state.in_city[state.at[o]]:
			return plane
		random_plane = plane
	return random_plane


# Find an airport in the same city as the location
func find_airport(state, l):
	for a in state.airports:
		if state.in_city[a] == state.in_city[l]:
			return a
	return false


## Methods to call the actions


func m_drive_truck(state, t, l):
	if t in state.trucks and l in state.locations and state.in_city[state.truck_at[t]] == state.in_city[l]:
		return [["drive_truck", t, l]]


func m_load_truck(state, o, t):
	if o in state.packages and t in state.trucks and state.at[o] == state.truck_at[t]:
		return [["load_truck", o, t]]


func m_unload_truck(state, o, l):
	if o in state.packages and state.at[o] in state.trucks and l in state.locations:
		return [["unload_truck", o, l]]


func m_fly_plane(state, plane, a):
	if plane in state.airplanes and a in state.airports:
		return [["fly_plane", plane, a]]


func m_load_plane(state, o, plane):
	if o in state.packages and plane in state.airplanes and state.at[o] == state.plane_at[plane]:
		return [["load_plane", o, plane]]


func m_unload_plane(state, o, a):
	if o in state.packages and state.at[o] in state.airplanes and a in state.airports:
		return [["unload_plane", o, a]]


## Other methods


func move_within_city(state, o, l):
	if o in state.packages and state.at[o] in state.locations and state.in_city[state.at[o]] == state.in_city[l]:
		var t = find_truck(state, o)
		if t:
			return [["truck_at", t, state.at[o]], ["at", o, t], ["truck_at", t, l], ["at", o, l]]
	return false


func move_between_airports(state, o, a):
	if (
		o in state.packages
		and state.at[o] in state.airports
		and a in state.airports
		and state.in_city[state.at[o]] != state.in_city[a]
	):
		var plane = find_plane(state, o)
		if plane:
			return [["plane_at", plane, state.at[o]], ["at", o, plane], ["plane_at", plane, a], ["at", o, a]]
	return false


func move_between_city(state, o, l):
	if o in state.packages and state.at[o] in state.locations and state.in_city[state.at[o]] != state.in_city[l]:
		var a1 = find_airport(state, state.at[o])
		var a2 = find_airport(state, l)
		if a1 and a2:
			return [["at", o, a1], ["at", o, a2], ["at", o, l]]
	return false


var state1: Dictionary


func before_each():
	state1.clear()
	planner._domains.push_back(the_domain)

	# If we've changed to some other domain, this will change us back.
	planner.current_domain = the_domain
	planner.declare_actions(
		[
			Callable(self, "drive_truck"),
			Callable(self, "load_truck"),
			Callable(self, "unload_truck"),
			Callable(self, "fly_plane"),
			Callable(self, "load_plane"),
			Callable(self, "unload_plane")
		]
	)

	planner.declare_unigoal_methods(
		"at",
		[
			Callable(self, "m_load_truck"),
			Callable(self, "m_unload_truck"),
			Callable(self, "m_load_plane"),
			Callable(self, "m_unload_plane")
		]
	)
	planner.declare_unigoal_methods("truck_at", [Callable(self, "m_drive_truck")])
	planner.declare_unigoal_methods("plane_at", [Callable(self, "m_fly_plane")])

	planner.declare_unigoal_methods(
		"at",
		[
			Callable(self, "move_within_city"),
			Callable(self, "move_between_airports"),
			Callable(self, "move_between_city")
		]
	)

#	planner.print_domain()

	state1.packages = ["package1", "package2"]
	state1.trucks = ["truck1", "truck6"]
	state1.airplanes = ["plane2"]
	state1.locations = ["location1", "location2", "location3", "airport1", "location10", "airport2"]
	state1.airports = ["airport1", "airport2"]
	state1.cities = ["city1", "city2"]

	state1.at = {"package1": "location1", "package2": "location2"}
	state1.truck_at = {"truck1": "location3", "truck6": "location10"}
	state1.plane_at = {"plane2": "airport2"}
	state1.in_city = {
		"location1": "city1",
		"location2": "city1",
		"location3": "city1",
		"airport1": "city1",
		"location10": "city2",
		"airport2": "city2"
	}


func test_move_goal_1():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "package1", "location2"], ["at", "package2", "location3"]])
	assert_eq(plan, [["drive_truck", "truck1", "location1"], ["load_truck", "package1", "truck1"], ["drive_truck", "truck1", "location2"], ["unload_truck", "package1", "location2"], ["load_truck", "package2", "truck1"], ["drive_truck", "truck1", "location3"], ["unload_truck", "package2", "location3"]])


##	Goal 2: package1 is at location10 (transport to a different city)
func test_move_goal_2():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "package1", "location10"]])
	assert_eq(plan, [["drive_truck", "truck1", "location1"], ["load_truck", "package1", "truck1"], ["drive_truck", "truck1", "airport1"], ["unload_truck", "package1", "airport1"], ["fly_plane", "plane2", "airport1"], ["load_plane", "package1", "plane2"], ["fly_plane", "plane2", "airport2"], ["unload_plane", "package1", "airport2"], ["drive_truck", "truck6", "airport2"], ["load_truck", "package1", "truck6"], ["drive_truck", "truck6", "location10"], ["unload_truck", "package1", "location10"]])


## Goal 3: package1 is at location1 (no actions needed)
func test_move_goal_3():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "package1", "location1"]])
	assert_eq(plan, [])


##	Goal 4: package1 is at location2
func test_move_goal_4():
	var plan = planner.find_plan(state1.duplicate(true), [["at", "package1", "location2"]])
	assert_eq(plan,  [["drive_truck", "truck1", "location1"], ["load_truck", "package1", "truck1"], ["drive_truck", "truck1", "location2"], ["unload_truck", "package1", "location2"]])
