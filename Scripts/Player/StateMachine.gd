extends Node

class_name PlayerStateMachine
## Holds Mario's states (the child nodes) and runs exactly one of them at a time.
##
## Each child node is a state with a script that `extends PlayerState`.
## The node's NAME is the state's name: transition_to("Air") switches to the child called "Air".
## To add your own move, add a child Node, give it a script extending PlayerState, and call
## machine.transition_to("YourNodeName") from another state. See the guide for examples.

signal state_changed(old_state: StringName, new_state: StringName)

@export var initial_state: NodePath

var state: PlayerState
var states: Dictionary = {}     # StringName -> PlayerState
var player: PlayerUpdated


func setup(owner_player: PlayerUpdated) -> void:
	player = owner_player
	for child in get_children():
		if child is PlayerState:
			child.player = player
			child.machine = self
			states[child.name] = child
	var first: PlayerState = get_node_or_null(initial_state) as PlayerState
	if first == null and states.has(&"Ground"):
		first = states[&"Ground"]
	if first == null and not states.is_empty():
		first = states.values()[0]
	state = first
	if state:
		state.enter({})


func physics_update(delta: float) -> void:
	if state:
		state.physics_update(delta)


func has_state(state_name: StringName) -> bool:
	return states.has(state_name)


func is_in(state_name: StringName) -> bool:
	return state != null and state.name == state_name


## Switch state. `msg` is an optional Dictionary passed to the new state's enter().
func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_warning("PlayerStateMachine: there is no state called '%s'" % state_name)
		return
	var old_name: StringName = state.name if state else &""
	if state:
		state.exit()
	state = states[state_name]
	state.enter(msg)
	state_changed.emit(old_name, state_name)
