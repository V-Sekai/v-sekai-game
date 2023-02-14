extends Resource
class_name Multigoal

## creates an object that represents a conjunctive goal, i.e., the goal of reaching a state that contains
## all of the state-variable bindings in g.
##
##	goal_name is the name to use for the new multigoal.
##	The keyword args are names and desired values of state variables.
##
##  [codeblock]
##	Example: here are three equivalent ways to specify a goal named 'goal1'
##	in which boxes b and c are located in room2 and room3:
##		First:
##		   g = Multigoal('goal1')
##		   g.loc = {}   # create a dictionary for things like loc['b']
##		   g.loc['b'] = ss'room2'
##		   g.loc['c'] = 'room3'
##		Second:
##		   g = Multigoal('goal1', loc={})
##		   g.loc['b'] = 'room2'
##		   g.loc['c'] = 'room3'
##		Third:
##		   g = Multigoal('goal1',loc={'b':'room2', 'c':'room3'})
##  [/codeblock]


var _state: Dictionary = {}

@export var state: Dictionary = {}:
	get:
		return _state
	set(value):
		_state = value

##		multigoal_name is the name to use for the multigoal. The keyword
##		args are the names and desired values of state variables.
func _init(multigoal_name, state_variables: Dictionary):
	resource_name = multigoal_name
	_state = state_variables


##		Print the multigoal's state-variables and their values.
##		 - heading (optional) is a heading to print beforehand.
func display(heading: String = "") -> void:
	print(heading)
	print(_state)

## Return a list of all state-variable names in the multigoal.
func state_vars() -> Array:
	var variable_list: Array = []
	var properties: Array = _state.keys()
	for v in properties:
		for p in v.keys():
			if p != get_name():
				variable_list.push_back(v.get(p))
	return variable_list
