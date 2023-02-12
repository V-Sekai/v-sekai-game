extends Node
#"""
#An expanded version of the "travel from home to the park" example in
#my lectures.
#-- Dana Nau <nau@umd.edu>, July 20, 2021
#"""

# Rather than hard-coding the domain name, use the name of the current file.
# This makes the code more portable.
var domain_name = scene_file_path
var the_domain = preload("../core/domain.gd").new("plan")

var planner = preload("../core/plan.gd").new()

################################################################################
# states and rigid relations

# These types are used by the 'is_a' helper function, later in this file
@export var types = {
	"person": ["alice", "bob"],
	"location": ["home_a", "home_b", "park", "station"],
	"taxi": ["taxi1", "taxi2"],
}
@export var dist : Dictionary = {
	["home_a", "park"]: 8,
	["home_b", "park"]: 2,
	["station", "home_a"]: 1,
	["station", "home_b"]: 7,
	["home_a", "home_b"]: 7,
	["station", "park"]: 9,
}

# prototypical initial state
var state0 : Dictionary = {
	"loc":  {"alice": "home_a", "bob": "home_b", "taxi1": "park", "taxi2": "station"},
	"cash": {"alice": 20, "bob": 15},
	"owe":  {"alice": 0, "bob": 0}
}


###############################################################################
# Helper functions:


func taxi_rate(dist):
	"In this domain, the taxi fares are quite low :-)"
	return 1.5 + 0.5 * dist


func distance(x, y):
	"""
	If rigid.dist[(x,y)] = d, this function figures out that d is both
	the distance from x to y and the distance from y to x.
	"""
	var result = dist.get([x, y])
	if result > 0:
		return result
	result = dist.get([y, x])
	if result > 0 :
		return result
	return 0


func is_a(variable, type):
	"""
	In most classical planners, one would declare data-types for the parameters
	of each action, and the data-type checks would be done by the planner.
	GTPyhop doesn't have a way to do that, so the 'is_a' function gives us a
	way to do it in the preconditions of each action, command, and method.

	'is_a' doesn't implement subtypes (e.g., if rigid.type[x] = y and
	rigid.type[x] = z, it doesn't infer that rigid.type[x] = z. It wouldn't be
	hard to implement this, but it isn't needed in the simple-travel domain.
	"""
	return variable in types[type]


###############################################################################
# Actions:


func walk(state, args):
	var p = args[0]  
	var x = args[1]  
	var y = args[2] 
	if is_a(p, "person") and is_a(x, "location") and is_a(y, "location") and x != y:
		if state.loc[p] == x:
			state.loc[p] = y
			return state


func call_taxi(state, args):
	var p = args[0]  
	var x = args[1] 
	if is_a(p, "person") and is_a(x, "location"):
		state.loc["taxi1"] = x
		state.loc[p] = "taxi1"
		return state


func ride_taxi(state, args):
	var p = args[0]  
	var y = args[1] 
	# if p is a person, p is in a taxi, and y is a location:
	if is_a(p, "person") and is_a(state.loc[p], "taxi") and is_a(y, "location"):
		var taxi = state.loc[p]
		var x = state.loc[taxi]
		if is_a(x, "location") and x != y:
			state.loc[taxi] = y
			state.owe[p] = taxi_rate(distance(x, y))
			return state


func pay_driver(state, args):
	var p = args[0]  
	var y = args[1] 
	if is_a(p, "person"):
		if state.cash[p] >= state.owe[p]:
			state.cash[p] = state.cash[p] - state.owe[p]
			state.owe[p] = 0
			state.loc[p] = y
			return state


###############################################################################
# Commands:


# this does the same thing as the action model
func c_walk(state, args):
	var p = args[0] 
	var x = args[1] 
	var y = args[2] 
	if is_a(p, "person") and is_a(x, "location") and is_a(y, "location"):
		if state.loc[p] == x:
			state.loc[p] = y
			return state


# c_call_taxi, version used in simple_tasks1
# this is like the action model except that the taxi doesn't always arrive
func c_call_taxi(state, args):
	var p = args[0] 
	var x = args[1] 
	if is_a(p, "person") and is_a(x, "location"):
		var rand : RandomNumberGenerator = RandomNumberGenerator.new()
		if rand.randfrange(2) > 0:
			state.loc["taxi1"] = x
			state.loc[p] = "taxi1"
			print("Action> c_call_taxi succeeded.  This happens with Pr = 1/2.")
			return state
		else:
			print("Action> c_call_taxi failed.  This happens with Pr = 1/2.")


# c_ride_taxi, version used in simple_tasks1
# this does the same thing as the action model
func c_ride_taxi(state, args):
	var p = args[0] 
	var y = args[1] 
	# if p is a person, p is in a taxi, and y is a location:
	if is_a(p, "person") and is_a(state.loc[p], "taxi") and is_a(y, "location"):
		var taxi = state.loc[p]
		var x = state.loc[taxi]
		if is_a(x, "location") and x != y:
			state.loc[taxi] = y
			state.owe[p] = taxi_rate(distance(x, y))
			return state


# this does the same thing as the action model
func c_pay_driver(state, args):
	return pay_driver(state, args)




###############################################################################
# Methods:


func do_nothing(state, args):
	var p = args[0] 
	var y = args[1] 
	if is_a(p, "person") and is_a(y, "location"):
		var x = state.loc[p]
		if x == y:
			return []


func travel_by_foot(state, args):
	var p = args[0] 
	var y = args[1] 
	if is_a(p, "person") and is_a(y, "location"):
		var x = state.loc[p]
		if x != y and distance(x, y) <= 2:
			return [["walk", p, x, y]]


func travel_by_taxi(state, args):
	var p = args[0] 
	var y = args[1] 
	if is_a(p, "person") and is_a(y, "location"):
		var x = state.loc[p]
		if x != y and state.cash[p] >= taxi_rate(distance(x, y)):
			return [["call_taxi", p, x], ["ride_taxi", p, y], ["pay_driver", p, y]]


func _ready():
	planner._domains.push_back(the_domain)
	planner.current_domain = the_domain
	planner.declare_actions([
		Callable(self, "walk"), 
		Callable(self, "call_taxi"), 
		Callable(self, "ride_taxi"), 
		Callable(self, "pay_driver")
		])
	planner.declare_commands([
			Callable(self, "c_walk"), 
			Callable(self, "c_call_taxi"), 
			Callable(self, "c_ride_taxi"),
			Callable(self, "c_pay_driver")
		])
	planner.declare_task_methods(
		"travel", 
		[Callable(self, "do_nothing"), 
		Callable(self, "travel_by_foot"), 
		Callable(self, "travel_by_taxi")])

	###############################################################################
	# Running the examples

	print("-----------------------------------------------------------------------")
	print("Created the domain '%s'. To run the examples, type this:" % domain_name)
	print("%s.main()" % domain_name)

	planner.current_domain = the_domain
	planner.print_domain()

	var state1 = state0.duplicate(true)

	print("Initial state is %s" % state1)

	print(
		"""
Use find_plan to plan how to get Alice from home to the park.
We'll do it several times with different values for 'verbose'.
"""
	)

	var expected = [
		["call_taxi", "alice", "home_a"],
		["ride_taxi", "alice", "park"],
		["pay_driver", "alice", "park"],
	]

	print("-- If verbose=0, the planner will return the solution but print nothing.")
	planner.verbose = 0
	var result = planner.find_plan(state1, [["travel", "alice", "park"]])
	print("Result %s" % [result])
	assert(result == expected)

	print("-- If verbose=1, the planner will print the problem and solution,")
	print("-- and then return the solution.\n")
	planner.verbose = 1
	result = planner.find_plan(state1, [["travel", "alice", "park"]])
	print("Result %s" % [result])
	assert(result == expected)

	print("-- If verbose=2, the planner will print the problem, a note at each")
	print("-- recursive call, and the solution. Then it will return the solution.")
	planner.verbose = 2
	result = planner.find_plan(state1, [["travel", "alice", "park"]])
	print("Result %s" % [result])
	assert(result == expected)

	print("-- If verbose=3, the planner will print even more information.")
	planner.verbose = 3
	result = planner.find_plan(state1, [["travel", "alice", "park"]])
	print("Result %s" % [result])
	assert(result == expected)

	print(
		"Find a plan that will first get Alice to the park, then get Bob to the park."
	)
	planner.verbose = 2
	var plan = planner.find_plan(
		state1, [["travel", "alice", "park"], ["travel", "bob", "park"]]
	)

	print("Plan %s" % [plan])
	assert(plan == [
			["call_taxi", "alice", "home_a"],
			["ride_taxi", "alice", "park"],
			["pay_driver", "alice", "park"],
			["walk", "bob", "home_b", "park"],
	])

	print(
		"""Next, we'll use run_lazy_lookahead to try to get Alice to the park. With
Pr = 1/2, the taxi won't arrive. In this case, run_lazy_lookahead will call
find_plan again, and find_plan will return the same plan as before. This will
happen repeatedly until either the taxi arrives or run_lazy_lookahead decides
it has tried too many times."""
	)

	planner.verbose = 1
	var new_state = planner.run_lazy_lookahead(state1, [["travel", "alice", "park"]])

	print("")
	print("If run_lazy_lookahead succeeded, then Alice is now at the park,")
	print("so the planner will return an empty plan: ")

	plan = planner.find_plan(new_state, [["travel", "alice", "park"]])
	print("Plan %s" % [plan])
#	assert(plan == [])

	print("No more examples")
