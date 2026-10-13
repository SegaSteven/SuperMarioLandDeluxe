class_name Layers
extends RefCounted
## Names for the physics layers in Project Settings > Layer Names > 2D Physics.
## Use them like:  set_collision_mask_value(Layers.GROUND, true)

const PLAYER := 1
const GROUND := 2
const ENEMY := 3
const KOOPA_STOMP := 4
const OBSTACLE := 5   # blocks, bricks, pipes
const BONUS := 6      # mushrooms, flowers, stars, hearts
const FIREBALL := 7   # superballs
const MAP_TILE := 8
const PLANT := 9      # piranha plants

## Bitmask for "things that stop walking characters": ground + obstacles.
const WORLD_MASK := 18

static func bit(layer: int) -> int:
	return 1 << (layer - 1)
