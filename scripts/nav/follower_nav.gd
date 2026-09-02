extends Node
## FollowerNav — autoload that gives the AI followers (the male and the cats) a
## real navigation map to path over, fixing the Phase 7 "follower gets stuck"
## bug where straight-line steering to the female routinely tried to cross walls,
## the open stairwell pit, the stair railing, the cross-wall or the ground-floor
## divider.
##
## A single NavigationRegion3D (built by CottageBuilder, in the "nav_region"
## group) is baked ONCE at runtime from the cottage's own StaticBody3D collision
## geometry (see cottage_builder._build_navigation). This helper locates that
## region and hands the followers its navigation map so they can call
## NavigationServer3D.map_get_path to route around real obstacles and up the
## staircase.
##
## IMPORTANT (validated in probes): map_get_path returns waypoints whose Y is NOT
## reliable for multi-floor meshes — only the XZ routing is trustworthy. Followers
## therefore steer toward waypoints in the horizontal plane only and let gravity +
## move_and_slide carry them up/down the ramp, which is exactly how the player
## controller already moves.

var _region: NavigationRegion3D = null
var _map: RID = RID()

func _ready() -> void:
	process_physics_priority = -10   # resolve the region before followers steer

func _physics_process(_delta: float) -> void:
	if _map.is_valid():
		return
	_region = get_tree().get_first_node_in_group("nav_region")
	if _region != null:
		_map = _region.get_navigation_map()

func has_map() -> bool:
	return _map.is_valid()

func map_is_valid() -> bool:
	return _map.is_valid()

## A navigation path (XZ-routing valid; Y unreliable) from `from` to `to`.
## Returns an empty array when no map is available yet or no path exists.
func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not _map.is_valid() or _region == null:
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(_map, from, to, true)
