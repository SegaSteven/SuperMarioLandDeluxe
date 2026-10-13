extends Node

class_name PlayerState
## Base class for one of Mario's states. Override what you need:
##   enter(msg)            - runs once when Mario switches into this state
##   exit()                - runs once when he leaves it
##   physics_update(delta) - runs every physics frame while this state is active
## Useful things you can reach from a state:
##   player   - Mario (PlayerUpdated). All his helpers: player.run_movement(delta), player.start_jump(),
##              player.velocity, player.is_on_floor(), player.player_mode, player.facing_dir ...
##   machine  - the state machine: machine.transition_to("Air")

var player: PlayerUpdated
var machine: PlayerStateMachine

## Can enemies / pickups touch Mario in this state? (false while growing, in a pipe, dead)
@export var allows_contacts: bool = true
## Can Mario be hurt in this state?
@export var allows_damage: bool = true
## Can Mario squash enemies by landing on them? (false in the submarine: touching hurts)
@export var allows_stomp: bool = true
## Can mushrooms / flowers change Mario's size here? (false in vehicles - they just give points)
@export var allows_transform: bool = true


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


## Called when something hurts Mario in this state. Return true if you handled it yourself
## (e.g. the submarine dies in one hit); return false for the normal shrink-or-die.
func on_hurt(_source: Node) -> bool:
	return false
