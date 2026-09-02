class_name NavPathFollower
## Reusable navigation-path steering state shared by the AI followers (the male
## in PlayerController and each discovered Cat). Replaces the old crude direct
## steering + side-step/detour stuck-recovery, which could not route around the
## cottage's walls, the open stairwell pit, the stair railing, the cross-wall or
## the ground-floor divider.
##
## Each frame the owner passes its world position and the follow target; this
## returns a horizontal (XZ) unit direction to walk. The actual steering uses the
## navigation map baked by CottageBuilder: the follower heads for the next waypoint
## of a NavigationServer3D.map_get_path route rather than straight at the target,
## so it genuinely goes AROUND obstacles and up the staircase.
##
## Because map_get_path waypoint Y is unreliable on multi-floor meshes, only the
## XZ is used here; the owner's gravity + move_and_slide carry it vertically, which
## is how the player controller already moves. Arrival/stop is decided by the owner
## on the full 3D distance, so followers still stop only when actually co-located.

var follow_target: Vector3 = Vector3.INF
var stop_distance: float = 1.6
var path_recalc_interval: float = 0.35

var path: PackedVector3Array = PackedVector3Array()
var _idx: int = 0
var _recalc: float = 0.0
var _last_from := Vector3.INF
var _stall := 0.0

## Returns a horizontal unit wish direction (Vector3.ZERO => stand still).
## `from` should be the body's global_position; `delta` the physics step.
func wish(from: Vector3, delta: float) -> Vector3:
	if follow_target == Vector3.INF:
		return Vector3.ZERO
	var to := follow_target - from
	to.y = 0.0

	# Arrival: stop only when the leader's XZ is nearby AND we are roughly level
	# with it. The vertical check is what stops a follower wiring out on the
	# staircase: a leader standing at the crest is 1-2m deeper into the slope and
	# up to a metre higher, so a pure flat-distance OR 3D-distance test would halt
	# the follower mid-slope instead of letting it crest onto the landing. Level
	# also means we never freeze while the leader is on another floor (stage 9).
	var to3 := follow_target - from
	if Vector2(to3.x, to3.z).length() < stop_distance and absf(to3.y) < 0.2:
		return Vector3.ZERO

	var nav := _get_nav_autoload()
	if nav == null or not nav.has_map():
		# No nav yet: direct steering fallback keeps behaviour sensible on frame 0.
		if to.length() < 0.01:
			return Vector3.ZERO
		return to.normalized()

	_recalc -= delta
	_rebuild_if_needed(from)

	# Find the first waypoint (in XZ) that is not still on top of us.
	var from2 := Vector2(from.x, from.z)
	while _idx < path.size():
		var wp := Vector2(path[_idx].x, path[_idx].z)
		if from2.distance_to(wp) > 0.4:
			break
		_idx += 1

	if _idx >= path.size():
		# Route exhausted: steer straight at the target.
		if to.length() < 0.01:
			return Vector3.ZERO
		return to.normalized()

	var wp3 := path[_idx]
	var w := Vector3(wp3.x - from.x, 0.0, wp3.z - from.z)
	if w.length() < 0.01:
		_idx += 1
		if to.length() < 0.01:
			return Vector3.ZERO
		return to.normalized()

	# Mild stall guard: if the target moved or we've made no progress, refresh.
	var moved := 0.0
	if _last_from != Vector3.INF:
		moved = Vector2(from.x - _last_from.x, from.z - _last_from.z).length()
	_last_from = from
	if moved < 0.02:
		_stall += delta
	else:
		_stall = 0.0
	if _stall > 1.0:
		_stall = 0.0
		_force_rebuild()

	return w.normalized()

func _rebuild_if_needed(from: Vector3) -> void:
	var target_moved := follow_target.distance_to(_last_target_for_path()) > 1.0
	if path.is_empty() or _recalc <= 0.0 or _idx >= path.size() or target_moved:
		_rebuild(from)

func _last_target_for_path() -> Vector3:
	if path.is_empty():
		return Vector3.INF
	return path[path.size() - 1]

func _force_rebuild() -> void:
	_rebuild(_last_from)

func _rebuild(from: Vector3) -> void:
	var nav := _get_nav_autoload()
	if nav == null:
		return
	path = nav.path(from, follow_target)
	_idx = 0
	_recalc = path_recalc_interval
	if not path.is_empty():
		# Skip the start point (== from) so we don't immediately "reach" it.
		var f2 := Vector2(from.x, from.z)
		var first := Vector2(path[0].x, path[0].z)
		if first.distance_to(f2) < 0.6:
			_idx = 1
	else:
		_idx = 0

func _get_nav_autoload() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("FollowerNav")
