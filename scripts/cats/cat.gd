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
# Navigation-path follower (Phase 7 fix): the cat walks a real nav path over the
# baked cottage mesh instead of a straight line at its leader, so it routes around
# walls/the stairwell pit/the cross-wall and up the staircase like the male.
var _nav_follower := NavPathFollower.new()

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
	var wish := _compute_follow_wish(delta)
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

## Phase 7 fix: the cat's steering wish, produced by walking a real navigation
## path (ArroundObstacles/UpTheStairs) to its leader instead of a straight line
## that tried to cross walls, the stairwell pit or the cross-wall. Delegates to the
## shared NavPathFollower; falls back to direct steering until the nav mesh is
## ready.
func _compute_follow_wish(delta: float) -> Vector3:
	if follow_target == Vector3.INF:
		return Vector3.ZERO
	_nav_follower.follow_target = follow_target
	_nav_follower.stop_distance = follow_stop_distance
	return _nav_follower.wish(global_position, delta)

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