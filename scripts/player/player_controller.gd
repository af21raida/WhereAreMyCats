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

# Stuck-escape state for the male follower (see _apply_stuck_escape).
var _stuck_time := 0.0
var _stuck_turn := 1.0
var _last_pos := Vector3.INF
# Path-recalc (detour) state, same idea as the cats: once the male has been
# stalled well past the side-step, he walks to a concrete bypass waypoint instead
# of hugging a wall forever. Trigger is long (3.0s) so normal following behaviour
# is completely unchanged.
var _detour := Vector3.INF
var _detour_side := 1.0
var _detour_start_dist := 0.0
var _detour_no_progress := 0.0
const DETOUR_GAP := 1.2
const STUCK_RECALC_TIME := 3.0

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
		wish = _apply_stuck_escape(delta, _read_follow_direction())
		wish = _apply_detour(delta, wish)

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

## Small obstacle escape for the follower (the male never gets player input).
## Straight-line steering can jam him against a wall/corner; once he has been
## far from the target but making no progress for a while, we side-step
## perpendicular to the direct line so he slides around the block. The side
## alternates each stall so he does not hug one wall forever, and as soon as he
## makes progress again the direct steering resumes.
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

## Recalculated path for prolonged stalls (mirrors the cats' detour): after the
## side-step has been failing for a while the male walks to a concrete bypass
## waypoint off to one side, then resumes steering toward the female. Needed so he
## can round the new closed hallway doors / wall corners instead of sticking.
func _apply_detour(delta: float, wish: Vector3) -> Vector3:
	if follow_target == Vector3.INF:
		return wish
	var dist := follow_target.distance_to(global_position)
	if _detour == Vector3.INF:
		if _stuck_time >= STUCK_RECALC_TIME and dist > follow_start_distance:
			_begin_detour(dist)
		else:
			_detour_no_progress = 0.0
		return wish
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
		_begin_detour(dist)
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
	_detour = global_position + (away + perp).normalized() * clampf(DETOUR_GAP + 0.9, 1.3, 2.5)
	_detour_no_progress = 0.0
	_stuck_time = 0.9   # don't instantly re-trigger while walking the waypoint

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
