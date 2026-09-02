class_name PlayerController
extends CharacterBody3D
## Shared controller for both protagonists. Movement, collision, gravity, and
## simple "follow the female protagonist" behaviour for the male.
##
## The female is the sole controlled protagonist (can_be_controlled = true and
## is set active by PlayerManager). The male is never controlled
## (can_be_controlled = false); he follows the female to stay together and never
## receives player input, so he cannot interact on his own.

signal active_changed(is_active_now: bool)

@export var move_speed: float = 4.0
@export var acceleration: float = 10.0
@export var can_be_controlled: bool = true
@export var follow_speed_factor: float = 0.7
@export var follow_stop_distance: float = 1.6
@export var follow_start_distance: float = 2.6
@export var character_id: StringName = &""

var is_active: bool = false
var follow_target: Vector3 = Vector3.INF
var _last_follow_dir := Vector3.ZERO

var _horizontal_velocity := Vector3.ZERO
var _model: Node3D

# Navigation-path follower (Phase 7 fix). Instead of the old crude straight-line
# steering + side-step/detour stuck-recovery (which could not route around the
# cottage walls, the open stairwell pit, the stair railing, the cross-wall or the
# ground-floor divider), the follower walks a real NavigationServer3D.map_get_path
# route over the bakery nav mesh, so it goes AROUND obstacles and UP the staircase
# to reach the female.
var _nav_follower := NavPathFollower.new()

func _ready() -> void:
	_model = get_node_or_null("Model")
	add_to_group("player")
	# PlayerManager finds us via the "player" group and configures active/follow.

## Called once by the manager when the character is (de)activated.
func set_active(value: bool) -> void:
	if is_active == value:
		return
	is_active = value
	if not is_active:
		_horizontal_velocity = Vector3.ZERO
	active_changed.emit(is_active)

func _physics_process(delta: float) -> void:
	var wish := Vector3.ZERO

	if is_active and can_be_controlled:
		wish = _read_input_direction()
	else:
		wish = _compute_follow_wish(delta)

	var target_velocity := wish * move_speed * (1.0 if can_be_controlled else follow_speed_factor)
	_horizontal_velocity = _horizontal_velocity.move_toward(target_velocity, acceleration * delta)
	velocity = Vector3(_horizontal_velocity.x, velocity.y, _horizontal_velocity.z)
	_apply_gravity(delta)
	move_and_slide()

	if _horizontal_velocity.length() > 0.1 and _model:
		var target_yaw := atan2(_horizontal_velocity.x, _horizontal_velocity.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, 12.0 * delta)

## Direction (0..1) from player input, rotated to be relative to the camera so
## the character moves the way the player expects regardless of camera angle.
func _read_input_direction() -> Vector3:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_down", "move_up")
	)
	return _camera_relative(input_dir)

## Direction toward the follow target (usually the active character position).
## The arrival/stop decision uses the FULL 3D distance: the male may only stop
## when he is actually co-located with the female, not merely horizontally near
## her while standing on a different floor (which used to freeze him below/above
## her and looked like "sometimes stops following"). Steering itself stays
## horizontal; when the pair aligns vertically we keep the last heading.
## Kept for tests/debug; the nav path follower (_compute_follow_wish) is what the
## male actually steers with.
func _read_follow_direction() -> Vector3:
	if follow_target == Vector3.INF:
		return Vector3.ZERO
	var to := follow_target - global_position
	if to.length() < follow_stop_distance:
		return Vector3.ZERO
	var flat := Vector3(to.x, 0.0, to.z)
	if flat.length() < 0.05:
		return _last_follow_dir
	_last_follow_dir = flat.normalized()
	if to.length() < follow_start_distance:
		# Slow approach within the start/stop band for natural easing.
		var band := follow_start_distance - follow_stop_distance
		var t: float = clamp((to.length() - follow_stop_distance) / band, 0.0, 1.0)
		return _last_follow_dir * t
	return _last_follow_dir

## Phases 7 fix: the follower's steering wish, produced by walking a real
## navigation path (ArroundObstacles/UpTheStairs) instead of a straight line at the
## female. Delegates to the shared NavPathFollower; falls back to direct steering
## until the nav mesh is ready.
func _compute_follow_wish(delta: float) -> Vector3:
	if follow_target == Vector3.INF:
		return Vector3.ZERO
	_nav_follower.follow_target = follow_target
	_nav_follower.stop_distance = follow_stop_distance
	return _nav_follower.wish(global_position, delta)

func _camera_relative(input_dir: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	var movement_basis := cam.global_transform.basis
	var forward := -movement_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := movement_basis.x
	right.y = 0.0
	right = right.normalized()
	var dir := forward * input_dir.y + right * input_dir.x
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * delta
	else:
		velocity.y = -0.5
