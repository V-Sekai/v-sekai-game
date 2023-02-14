extends Resource

# SPDX-FileCopyrightText: 2021 University of Maryland
# [br]
# SPDX-License-Identifier: BSD-3-Clause-Clear
# [br]
# Author: Dana Nau <nau@umd.edu>, July 7, 2021
# [br]
# Author: K. S. Ernest (iFire) Lee <ernest.lee@chibifire.com>, August 28, 2022
# [br]
#
## A class for holding planning-and-acting domains.
##
## [br]
##
## d = Domain(domain_name) creates an object to contain the actions, commands,
## and methods for a planning-and-acting domain. 'domain_name' is the name to
## use for the new domain.


const verbose: int = 1


##	_m_verify_g is a method that GTPyhop uses to check whether a
##	unigoal method has achieved the goal for which it was used.
func _m_verify_g(
	state: Dictionary, method: String, state_var: String, arg: String, desired_val: Variant, depth: int
) -> Array:
	if state[state_var][arg] != desired_val:
		assert(
			false,
			(
				"Depth %s: method %s didn't achieve\n" % [depth, method]
				+ "Goal %s [%s] = %s" % [state_var, arg, desired_val]
			)
		)
	if verbose >= 3:
		print("Depth %s: method %s achieved\n" % [depth, method] + "Goal %s[%s] = %s" % [state_var, arg, desired_val])
	return []  # i.e., don't create any subtasks or subgoals


##	_goals_not_achieved takes two arguments: a state s and a multigoal g.
## [br]
##	It returns a dictionary of the goals in g that aren't true in s.
## [br]
##	For example, suppose
##		s.loc['c0'] = 'room0', g.loc['c0'] = 'room0',
##		s.loc['c1'] = 'room1', g.loc['c1'] = 'room3',
##		s.loc['c2'] = 'room2', g.loc['c2'] = 'room4'.
## [br]
##	Then _goals_not_achieved(s, g) will return
##		{'loc': {'c1': 'room3', 'c2': 'room4'}}
static func _goals_not_achieved(state: Dictionary, multigoal: Multigoal) -> Dictionary:
	var unachieved: Dictionary = {}
	for n in multigoal.state:
		for arg in multigoal.state.get(n):
			var val = multigoal.state.get(n).get(arg)
			if val != state.get(n).get(arg):
				# want arg_value_pairs.name[arg] = val
				if not unachieved.has(n):
					unachieved[n] = {}
				unachieved.get(n)[arg] = val
	return unachieved


##	_m_verify_g is a method that GTPyhop uses to check whether a multigoal
##	method has achieved the multigoal for which it was used.
func _m_verify_mg(state: Dictionary, method: String, multigoal: Multigoal, depth: int) -> Array:
	var goal_dict = _goals_not_achieved(state, multigoal)
	if goal_dict:
		print("Depth {depth}: method %s " % method + "didn't achieve %s" % multigoal)
		return []
	if verbose >= 3:
		print("Depth %s: method %s achieved %s" % [depth, method, multigoal])
	return []


## dictionary that maps each action name to the corresponding function
var _action_dict = {}

## dictionary that maps each command name to the corresponding function
var _command_dict = {}

## dictionary that maps each task name to a list of relevant methods
## _verify_g and _verify_mg are described later in this file.
var _task_method_dict = {
	"_verify_g": [Callable(self, "_m_verify_g")],
	"_verify_mg": [Callable(self, "_m_verify_mg")],
}

## dictionary that maps each unigoal name to a list of relevant methods
var _unigoal_method_dict = {}

## list of all methods for multigoals
var _multigoal_method_list = []


## domain_name is the name to use for the domain.
func _init(domain_name: String) -> void:
	set_name(domain_name)


## Print the domain's actions, commands, and methods.
func display() -> void:
	print(self)
