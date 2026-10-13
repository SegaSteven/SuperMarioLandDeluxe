class_name PowerUps
extends RefCounted
## THE POWER-UP LIST. Every power-up Mario can get is one entry here.
##
## Two kinds:
##   MODE  - changes what Mario IS until he's hit (mushroom, flowers, bunny ears).
##           Uses one of PlayerUpdated.PlayerMode. Getting hit drops him to small.
##   TIMED - an effect on top of whatever he is, for a few seconds (star, speed shoes).
##
## Fields:
##   name              shown in messages / for your own reference
##   kind              Kind.MODE or Kind.TIMED
##   mode              (MODE) the PlayerMode it turns Mario into
##   unlocked          true = available from the start; false = must be unlocked first
##                     (a door with Unlocks = "powerup_<id>", or OverworldMan.unlock("powerup_<id>"))
##   projectile        (MODE) scene thrown with the action button, "" = can't shoot
##   air_hold_state    (MODE) Mario state entered when jump is HELD while falling ("" = none)
##   anim_prefix       (MODE) animation names look like "<prefix>_idle", "<prefix>_run"...
##   fallback_prefix   (MODE) used when an animation is missing (so placeholder art still works)
##   tint              (MODE) colour multiplied onto Mario's sprite, until you draw real frames
##   duration          (TIMED) seconds; 0 = the length of its music
##   points            score for collecting it
##   item              the pickup scene for it (used by colour ? blocks)
##   switch            the colour switch (switch palace) that unlocks it: "blue", "red", "pink"
##
## ADDING YOUR OWN (e.g. a cape):
##   1. Add CAPE to the PlayerMode enum in Player_Updated.gd (at the END, so saves keep working).
##   2. Add an entry below: "cape": {"name": "Cape Feather", "kind": Kind.MODE, "mode": 5, ...}
##   3. Make an item: duplicate Scenes/PowerUps/fire_flower.tscn, set Power Up Id = "cape".
##   4. For a new ability, add a Mario state (Scripts/Player/States/) and name it in
##      air_hold_state, or switch to it from your own code.

enum Kind { MODE, TIMED }

## PlayerUpdated.PlayerMode values, written as numbers so this file has no dependency loop.
const SMALL := 0
const BIG := 1
const SHOOTING := 2
const FIRE := 3
const BUNNY := 4

const LIST := {
	"mushroom": {
		"name": "Super Mushroom", "kind": Kind.MODE, "mode": BIG, "unlocked": true,
		"projectile": "", "air_hold_state": "", "anim_prefix": "big", "fallback_prefix": "big",
		"tint": Color(1, 1, 1), "points": 1000,
	},
	"superball": {
		"name": "Superball Flower", "kind": Kind.MODE, "mode": SHOOTING, "unlocked": true,
		"projectile": "res://Scenes/superball.tscn", "air_hold_state": "",
		"anim_prefix": "shooting", "fallback_prefix": "big", "tint": Color(1, 1, 1), "points": 1000,
	},
	"fire": {
		"name": "Fire Flower", "kind": Kind.MODE, "mode": FIRE, "unlocked": false, "switch": "red",
		"projectile": "res://Scenes/PowerUps/player_fireball.tscn", "air_hold_state": "",
		"anim_prefix": "fire", "fallback_prefix": "big", "tint": Color(1.0, 0.72, 0.62), "points": 1000,
		"item": "res://Scenes/PowerUps/fire_flower.tscn",
	},
	"bunny": {
		"name": "Bunny Ears (Carrot)", "kind": Kind.MODE, "mode": BUNNY, "unlocked": false, "switch": "pink",
		"projectile": "", "air_hold_state": "BunnyFloat",
		"anim_prefix": "bunny", "fallback_prefix": "big", "tint": Color(1.0, 0.86, 0.95), "points": 1000,
		"item": "res://Scenes/PowerUps/carrot.tscn",
	},
	"speed_shoes": {
		"name": "Speed Shoes", "kind": Kind.TIMED, "unlocked": false, "switch": "blue",
		"duration": 10.0, "points": 1000, "item": "res://Scenes/PowerUps/speed_shoes.tscn",
	},
}


## SWITCH COLOURS (Super Mario World switch palaces). Pressing a colour's switch unlocks the
## power-up that names that colour above, and turns on that colour's blocks everywhere.
## Add a colour: a new entry here + "switch": "<name>" on a power-up.
const SWITCH_COLORS := {
	"blue": Color(0.25, 0.5, 1.0),
	"red": Color(0.95, 0.25, 0.2),
	"pink": Color(1.0, 0.5, 0.8),
}


static func switch_key(color_name: String) -> String:
	return "switch_" + color_name


static func is_switch_on(color_name: String) -> bool:
	return OverworldMan.is_unlocked(switch_key(color_name))


## The power-up id unlocked by this colour's switch ("" if none).
static func power_up_for_switch(color_name: String) -> String:
	for id in LIST:
		if LIST[id].get("switch", "") == color_name:
			return id
	return ""


## Presses a colour switch: turns its blocks on and unlocks its power-up. Saved.
static func press_switch(color_name: String) -> void:
	OverworldMan.unlock(switch_key(color_name))
	var id := power_up_for_switch(color_name)
	if id != "":
		unlock(id)


static func has(id: String) -> bool:
	return LIST.has(id)


static func get_data(id: String) -> Dictionary:
	return LIST.get(id, {})


## Data for whatever power-up gives this PlayerMode ({} for SMALL).
static func for_mode(mode: int) -> Dictionary:
	for id in LIST:
		var d: Dictionary = LIST[id]
		if d.get("kind") == Kind.MODE and d.get("mode") == mode:
			return d
	return {}


static func unlock_key(id: String) -> String:
	return "powerup_" + id


static func is_unlocked(id: String) -> bool:
	var d := get_data(id)
	if d.is_empty():
		return false
	return d.get("unlocked", false) or OverworldMan.is_unlocked(unlock_key(id))


static func unlock(id: String) -> void:
	OverworldMan.unlock(unlock_key(id))
