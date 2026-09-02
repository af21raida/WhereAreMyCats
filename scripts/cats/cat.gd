class_name Cat
extends CharacterBody3D
## A cat (Phase 7). Each cat is a build-in-code, low-poly PS1-style model (plain
## boxes + flat nearest-filtered materials, matching the cottage).
##
## DISCOVERY — exploration-based, NO hint prompts:
##   - While hidden the cat is a frozen visual prop (physics disabled, collision
##     off) sitting at its hiding spot; the player must find it by exploring.
##   - Ginger is revealed by opening the kitchen cabinet (wired in the builder).
##   - Tabby/Inej and Tuxedo/Void are revealed automatically when the female gets
##     close to their hiding spot (`reveal_on_proximity`). No prompt is shown.
##
## FOLLOWING — after discovery the cat joins the follower chain:
##   - `following` is turned on, physics/collision are enabled, and `CatManager`
##     sets `follow_target` to the companion ahead (the male, then the previous
##     cat). It reuses the same robust follow + stuck-escape behaviour as the male
##     companion (CharacterBody3D, floor collision, gravity), so it climbs stairs,
##     stays on floors, does not pass through walls, and recovers if blocked.
##   - The cat's collision only touches the world (never the players), so it never
##     interferes with player movement.
##
## Only the female discovers cats (proximity uses the female's position; Ginger
## requires the female to open the cabinet). The male never discovers them.

signal discovered(cat: Object)

@export var cat_id: StringName = &""
@export var display_name: String = "Cat"
@export var discovery_text: String = "You found cat!"
@export var hide_spot: String = ""
## When true, walking near this cat reveals it (no prompt needed). When false it
## must be revealed by a specific action (Ginger = opening the cabinet).
@export var reveal_on_proximity := true
@export var proximity_radius := 1.1

# Follower tuning (mirrors PlayerController's approach, scaled for a small cat).
@export var move_speed: float = 3.0
@export var follow_speed_factor: float = 0.75
@export var follow_stop_distance: float = 1.0
@export var follow_start_distance: float = 2.4
## Spacing this cat keeps behind the companion it trails (set per cat by the
## chain so followers never share the same target position).
@export var follow_gap: float = 1.0
## After this many seconds stalled far from the target (longer than the side-step
## in _apply_stuck_escape), the cat lays down a bypass waypoint and walks around
## the block — a real path recalc for walls/closed doors/furniture.
@export var stuck_recalc_time: float = 2.2

# PS1 palette for this cat.
@export var fur_color := Color(0.7, 0.45, 0.28)
@export var belly_color := Color(0.96, 0.9, 0.78)
@export var ear_inner_color := Color(0.9, 0.62, 0.58)
@export var stripe_color := Color(0.0, 0.0, 0.0, 0.0)   # alpha 0 = no stripes

var found: bool = false
var following: bool = false
var follow_target: Vector3 = Vector3.INF

var _model: Node3D
var _collision: CollisionShape3D
var _cache: Dictionary = {}
var _horizontal_velocity := Vector3.ZERO
var _last_follow_dir := Vector3.ZERO
# Stuck-escape state (copied from the male follower).
var _stuck_time := 0.0
var _stuck_turn := 1.0
var _last_pos := Vector3.INF
# Path-recalc (detour) state: a concrete bypass waypoint used after prolonged
# stalls, so the cat finds its way around walls/doors instead of sticking forever.
var _detour := Vector3.INF
var _detour_side := 1.0
var _detour_start_dist := 0.0
var _detour_no_progress := 0.0

func _ready() -> void:
	add_to_group("cat")
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	_build_model()
	_build_collision()
	# Physics body participates with the world only; never with the players, and
	# is disabled entirely until the cat is found (so it stays frozen in place
	# and can't interfere with the player before discovery).
	collision_layer = 0
	collision_mask = 0
	_set_collision_enabled(false)
	set_physics_process(true)

## Returns true only on the first successful discovery.
func reveal() -> bool:
	if found:
		return false
	found = true
	following = true
	rotation = Vector3.ZERO   # clears the build-time hiding pose
	_set_collision_enabled(true)
	discovered.emit(self)
	var mgr := get_tree().root.get_node_or_null("CatManager")
	if mgr != null:
		mgr.discover(self)
	return true

func _build_collision() -> void:
	_collision = CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = Vector3(0.28, 0.26, 0.42)
	_collision.shape = shp
	_collision.position = Vector3(0.0, 0.03, 0.0)
	add_child(_collision)
	floor_snap_length = 0.2

func _set_collision_enabled(enabled: bool) -> void:
	if _collision == null:
		return
	_collision.disabled = not enabled
	if enabled:
		collision_layer = 2   # cat layer: not in the players' mask
		collision_mask = 1    # world (walls, floors) only
	else:
		collision_layer = 0
		collision_mask = 0

func _physics_process(delta: float) -> void:
	_check_proximity_reveal()
	if not following:
		return
	var wish := _read_follow_direction()
	wish = _apply_stuck_escape(delta, wish)
	wish = _apply_detour(delta, wish)
	wish = _apply_separation(wish)
	var target_velocity := wish * move_speed * follow_speed_factor
	_horizontal_velocity = _horizontal_velocity.move_toward(target_velocity, 10.0 * delta)
	velocity = Vector3(_horizontal_velocity.x, velocity.y, _horizontal_velocity.z)
	_apply_gravity(delta)
	move_and_slide()
	_face_motion(delta)

func _check_proximity_reveal() -> void:
	if not reveal_on_proximity or found:
		return
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm == null or pm.active_player == null:
		return
	if global_position.distance_to(pm.active_player.global_position) <= proximity_radius:
		reveal()

func _read_follow_direction() -> Vector3:
	if follow_target == Vector3.INF:
		return Vector3.ZERO
	var to := follow_target - global_position
	var flat := Vector3(to.x, 0.0, to.z)
	# "Above or below" flag: while the target sits meaningfully ABOVE the cat (e.g.
	# halfway up the stairs while the leader is on the landing), arrival/easing must
	# NOT engage on the FLAT gap alone or the cat stops mid-ramp with its nose
	# under the upper floor. It only considers itself to have arrived once it is
	# close in XZ AND level with the target.
	var need_up: bool = to.y > 0.05
	if flat.length() < follow_stop_distance and not need_up:
		return Vector3.ZERO
	if flat.length() < 0.05 and not need_up:
		return _last_follow_dir
	_last_follow_dir = flat.normalized()
	if not need_up and flat.length() < follow_start_distance:
		var band := follow_start_distance - follow_stop_distance
		var t: float = clamp((flat.length() - follow_stop_distance) / band, 0.0, 1.0)
		return _last_follow_dir * t
	return _last_follow_dir

## Same obstacle escape as the male follower: if the cat is far from its target
## but has made no progress for a while, it side-steps to slide around a block.
func _apply_stuck_escape(delta: float, wish: Vector3) -> Vector3:
	if wish == Vector3.ZERO or follow_target == Vector3.INF:
		_stuck_time = 0.0
		return wish
	var moved := 0.0
	if _last_pos != Vector3.INF:
		moved = global_position.distance_to(_last_pos)
	_last_pos = global_position
	var dist := (follow_target - global_position).length()
	if dist <= follow_start_distance:
		_stuck_time = 0.0
		return wish
	if moved < 0.02:
		_stuck_time += delta
	else:
		_stuck_time = maxf(0.0, _stuck_time - delta)
	if _stuck_time < 0.6:
		return wish
	var perp := Vector3(-wish.z, 0.0, wish.x) * _stuck_turn
	if _stuck_time > 1.2:
		_stuck_turn = -_stuck_turn
		_stuck_time = 0.0
	return (wish.normalized() + perp * 0.9).normalized()

## Recalculated path: once the cat has been stalled for `stuck_recalc_time`
## seconds it stops hoping the side-step fixes it and actually walks to a concrete
## bypass waypoint off to one side; when that ends (or the direct line becomes
## clear again) it resumes steering toward its leader. This is the "recover after
## several seconds, recalc the path" behaviour requested on top of the side-step.
func _apply_detour(delta: float, wish: Vector3) -> Vector3:
	if follow_target == Vector3.INF:
		return wish
	var dist := follow_target.distance_to(global_position)
	if _detour == Vector3.INF:
		if _stuck_time >= stuck_recalc_time and dist > follow_start_distance:
			_begin_detour(dist)
		else:
			_detour_no_progress = 0.0
		return wish
	# Active bypass: if we are clearly closer to the target than when we started,
	# the block is behind us — go straight to the leader again.
	if dist < _detour_start_dist - 0.3:
		_detour = Vector3.INF
		_stuck_time = 0.0
		_stuck_turn = -_stuck_turn
		return wish
	var to_wp := _detour - global_position
	to_wp.y = 0.0
	if to_wp.length() < 0.5:
		_detour = Vector3.INF
		_stuck_time = 0.0
		return wish
	var moved := 0.0
	if _last_pos != Vector3.INF:
		moved = global_position.distance_to(_last_pos)
	if moved > 0.05:
		_detour_no_progress = 0.0
	else:
		_detour_no_progress += delta
	if _detour_no_progress > 1.5:
		_begin_detour(dist)   # the waypoint itself is blocked: flip side, retry
		return wish
	var target_dir := wish
	if target_dir == Vector3.ZERO:
		target_dir = (follow_target - global_position)
		target_dir.y = 0.0
		target_dir = target_dir.normalized() if target_dir.length() > 0.01 else Vector3.ZERO
	return (to_wp.normalized() + target_dir * 0.35).normalized()

func _begin_detour(dist: float) -> void:
	_detour_side = -_detour_side
	_detour_start_dist = dist
	var away := global_position - follow_target
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3(0.0, 0.0, -1.0)
	var perp := Vector3(-away.z, 0.0, away.x) * _detour_side
	_detour = global_position + (away + perp).normalized() * clampf(follow_gap + 0.9, 1.3, 2.5)
	_detour_no_progress = 0.0
	_stuck_time = 0.7   # don't instantly re-trigger while walking the waypoint

## Keeps followers from stacking: the cats never collide with each other or with
## the players (mask = world only), so without this they could merge. Blends a
## small repulsion away from anyone within arm's length into the wish.
func _apply_separation(wish: Vector3) -> Vector3:
	var others: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group("cat"):
		if n != self:
			others.append(n as Node3D)
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm != null:
		for p in get_tree().get_nodes_in_group("player"):
			if p != self:
				others.append(p as Node3D)
	var push := Vector3.ZERO
	for o in others:
		var d := global_position.distance_to(o.global_position)
		if d < 0.7 and d > 0.001:
			push += (global_position - o.global_position).normalized() * (0.7 - d)
	if push == Vector3.ZERO or wish == Vector3.ZERO:
		return wish
	return (wish.normalized() + push.normalized() * 0.5).normalized()

func _face_motion(delta: float) -> void:
	if _model == null:
		return
	if _horizontal_velocity.length() > 0.1:
		var target_yaw := atan2(_horizontal_velocity.x, _horizontal_velocity.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, 12.0 * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * delta
	else:
		velocity.y = -0.5

func _mat(c: Color) -> StandardMaterial3D:
	if _cache.has(c):
		return _cache[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_cache[c] = m
	return m

func _mesh(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)
	mi.set_surface_override_material(0, _mat(c))
	return mi

## Builds a sitting low-poly cat from boxes inside `_model`, feet at origin.
func _build_model() -> void:
	_mesh(_model, Vector3(0.26, 0.2, 0.34), Vector3(0.0, 0.2, -0.02), fur_color)
	_mesh(_model, Vector3(0.24, 0.12, 0.2), Vector3(0.0, 0.1, -0.14), fur_color)
	_mesh(_model, Vector3(0.2, 0.18, 0.2), Vector3(0.0, 0.16, 0.12), belly_color)
	_mesh(_model, Vector3(0.05, 0.14, 0.06), Vector3(-0.09, 0.09, 0.16), fur_color)
	_mesh(_model, Vector3(0.05, 0.14, 0.06), Vector3(0.09, 0.09, 0.16), fur_color)
	_mesh(_model, Vector3(0.2, 0.18, 0.19), Vector3(0.0, 0.34, 0.2), fur_color)
	_mesh(_model, Vector3(0.12, 0.06, 0.1), Vector3(0.0, 0.28, 0.29), belly_color)
	_mesh(_model, Vector3(0.08, 0.06, 0.04), Vector3(-0.08, 0.48, 0.2), fur_color)
	_mesh(_model, Vector3(0.08, 0.06, 0.04), Vector3(0.08, 0.48, 0.2), fur_color)
	_mesh(_model, Vector3(0.04, 0.03, 0.035), Vector3(-0.08, 0.46, 0.2), ear_inner_color)
	_mesh(_model, Vector3(0.04, 0.03, 0.035), Vector3(0.08, 0.46, 0.2), ear_inner_color)
	var tail := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.04, 0.04, 0.4)
	tail.mesh = tm
	tail.position = Vector3(0.0, 0.3, -0.22)
	tail.rotation_degrees = Vector3(-40.0, 0.0, 0.0)
	_model.add_child(tail)
	tail.set_surface_override_material(0, _mat(fur_color))
	if stripe_color.a > 0.0 and stripe_color != fur_color:
		for s in 3:
			_mesh(_model, Vector3(0.28, 0.03, 0.03),
				Vector3(0.0, 0.26, -0.12 + s * 0.09), stripe_color)