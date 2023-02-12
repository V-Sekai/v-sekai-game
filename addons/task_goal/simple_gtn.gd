extends Node
#"""
#An expanded version of the "travel from home to the park" example in
#my lectures, modified to use goals instead of tasks.
#-- Dana Nau <nau@umd.edu>, July 20, 2021
#"""


var domain_name = "simple_gtn"
var the_domain = preload("domain.gd").new(domain_name)

var planner = preload("plan.gd").new()


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

# initial goal
var goal1 : Multigoal = Multigoal.new("goal1")

# another initial goal
var goal2 = Multigoal.new("goal2")

# bigger initial goal
var goal3 = Multigoal.new("goal3")


###############################################################################
# Helper functions:


func taxi_rate(taxi_dist):
#	"In this domain, the taxi fares are quite low :-)"
	return 1.5 + 0.5 * taxi_dist


func distance(x, y):
#	"""
#	If rigid.dist[(x,y)] = d, this function figures out that d is both
#	the distance from x to y and the distance from y to x.
#	"""
	var result = dist.get([x, y])
	if result > 0:
		return result
	result = dist.get([y, x])
	if result > 0:
		return result
	return 0 


func is_a(variable, type):
#	"""
#	In most classical planners, one would declare data-types for the parameters
#	of each action, and the data-type checks would be done by the planner.
#	GTPyhop doesn't have a way to do that, so the 'is_a' function gives us a
#	way to do it in the preconditions of each action, command, and method.
#
#	'is_a' doesn't implement subtypes (e.g., if rigid.type[x] = y and
#	rigid.type[x] = z, it doesn't infer that rigid.type[x] = z. It wouldn't be
#	hard to implement this, but it isn't needed in the simple-travel domain.
#	"""
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
		var random_generator : RandomNumberGenerator = RandomNumberGenerator.new()
		var taxi = "taxi%s" % [1 + random_generator.randfn(2)]
		print("Action> the taxi is chosen randomly. This time it is %s." % [taxi])
		state.loc[taxi] = x
		state.loc[p] = taxi
		return state
		
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
	goal1.state["loc"] = {"alice": "park"}
	goal2.state["loc"] = {"bob": "park"}
	goal3.state["loc"] = {"alice": "park", "bob": "park"}
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

	###############################################################################
	# Running the examples

	print("-----------------------------------------------------------------------")
	print("Created the domain '%s'. To run the examples, type this:" % domain_name)
	print("%s.main()" % domain_name)

	planner.declare_unigoal_methods("loc", [Callable(self, "travel_by_foot"), Callable(self, "travel_by_taxi")])

	# GTPyhop provides a built-in multigoal method called m_split_multigoal to
	# separate a multigoal G into a collection of unigoals. It returns a list of
	# goals [g1, ..., gn, G], where g1, ..., gn are the unigoals in G that aren't
	# true in the current state. Since G is at the end of the list, seek_plan
	# will first plan for g1, ..., gn and then call m_split_multigoal again, in
	# order to re-achieve any goals that (due to deleted-condition interactions)
	# became false while accomplishing g1, ..., gn.

	# The main problem with m_split_multigoal is that it isn't smart about
	# choosing an order in which to achieve g1, ..., gn. Usually some orders
	# will work better than others, and a possible project would be to create a
	# heuristic function to choose a good order.

	planner.declare_multigoal_methods([planner.m_split_multigoal])

#	"""
#	Run various examples.
#	main() will pause occasionally to let you examine the output.
#	main(False) will run straight through to the end, without stopping.
#	"""

	# If we've changed to some other domain, this will change us back.
	planner.current_domain = the_domain
	planner.print_domain()

	var state1 = state0.duplicate(true)

	#    state1.display(heading='\nThe initial state is')

	print(
		"""
Next, several planning problems using the above domain and initial state.
"""
	)

	print(
		"""
Below, we give find_plan the goal of having alice be at the park.
We do it several times with different values for 'verbose'.
"""
	)

	var expected = [
		["call_taxi", "alice", "home_a"],
		["ride_taxi", "alice", "park"],
		["pay_driver", "alice", "park"],
	]

	print("If verbose=0, the planner returns the solution but prints nothing:")
	planner.verbose = 0
	var result = planner.find_plan(state1, [["loc", "alice", "park"]])
	print(result)
#	th.check_result(result, expected)

	print(
		"""If verbose=1, then in addition to returning the solution, the planner prints
both the problem and the solution"
"""
	)
	planner.verbose = 1
	result = planner.find_plan(state1, [["loc", "alice", "park"]])
	print(result)
#	th.check_result(result, expected)

	print(
		"""If verbose=2, the planner also prints a note at each recursive call.  Below,
_verify_g is a task used by the planner to check whether a method has
achieved its goal.
"""
	)
	planner.verbose = 2
	result = planner.find_plan(state1, [["loc", "alice", "park"]])
	print(result)
#	th.check_result(result, expected)
#	th.pause(do_pauses)

	print(
		"""
If verbose=3, the planner prints even more information. 
"""
	)
	planner.verbose = 3
	result = planner.find_plan(state1, [["loc", "alice", "park"]])
	print(result)
#	th.check_result(result, expected)

#	th.pause(do_pauses)
	print(
		"""
Next, we give find_plan a sequence of two goals: first for Alice to be at the
park, then for Bob to be at the park. Since this is a sequence, it doesn't
matter whether they're both at the park at the same time.
"""
	)

	planner.verbose = 2
	var plan = planner.find_plan(state1, [["loc", "alice", "park"], ["loc", "bob", "park"]])

#	th.check_result(
#		plan,
#		[
#			["call_taxi", "alice", "home_a"],
#			["ride_taxi", "alice", "park"],
#			["pay_driver", "alice", "park"],
#			["walk", "bob", "home_b", "park"],
#		],
#	)
#
#	th.pause(do_pauses)

#	state1.display(heading="\nInitial state")

	print(state1)

	print(
		"""
A multigoal g looks similar to a state, but usually it includes just a few of
the state variables rather than all of them. It specifies *desired* values
for those state variables, rather than current values. The goal is to produce
a state that satisfies all of the desired values.

Below, goal3 is the goal of having Alice and Bob at the park at the same time.
"""
	)

#	goal3.display()
	
	print(goal3.state)

	print(
		"""
Next, we'll call find_plan on goal3, with verbose=2. In the printout,
_verify_mg is a task used by the planner to check whether a multigoal
method has achieved all of the values specified in the multigoal.
"""
	)
#	th.pause(do_pauses)

	planner.verbose = 2
	plan = planner.find_plan(state1, [goal3])
#	th.check_result(
#		plan,
#		[
#			("call_taxi", "alice", "home_a"),
#			("ride_taxi", "alice", "park"),
#			("pay_driver", "alice", "park"),
#			("walk", "bob", "home_b", "park"),
#		],
#	)
	print(plan)
#	th.pause(do_pauses)
	print("Call run_lazy_lookahead with verbose=1:")

	planner.verbose = 1
	var new_state = planner.run_lazy_lookahead(state1, [["loc", "alice", "park"]])
	print("")

#	th.pause(do_pauses)

	print("Alice is now at the park, so the planner will return an empty plan:")

	planner.verbose = 1
	plan = planner.find_plan(new_state, [["loc", "alice", "park"]])
#	th.check_result(plan, [])

	print("No more examples")
