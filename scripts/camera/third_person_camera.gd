class_name ThirdPersonCamera
extends Node3D
## Third-person follow camera.
##
## Orbits the active (female) protagonist from behind with the mouse, supports
## mouse-wheel dolly zoom, and pulls in when geometry would clip the lens. Player
## movement stays camera-relative (see PlayerController), so W/A/S/D always move
## relative to the on-screen view. This replaced the Phase 2 fixed-camera manager
## as the main camera (fixed-camera code remains intact for easy reversion).

@export var camera_path: NodePath
@export var initial_yaw := 0.0
@export var initial_pitch := 0.35
@export var distance := 4.5
@export var min_distance := 1.5
@export var max_distance := 9.0
@export var zoom_step := 0.5
@export var orbit_speed := 0.005
@export var blend_speed := 8.0
@export var look_height := 1.5
@export var collision_margin := 0.15

var camera: Camera3D
var _yaw := 0.0
var _pitch := 0.0

func _ready() -> void:
	_yaw = initial_yaw
	_pitch = clampf(initial_pitch, -1.2, 1.2)
	if camera_path != NodePath():
		camera = get_node_or_null(camera_path) as Camera3D
	if camera != null:
		camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * orbit_speed
		_pitch = clampf(_pitch - event.relative.y * orbit_speed, -0.9, 1.2)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_step, min_distance, max_distance)

func _process(delta: float) -> void:
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm == null or pm.active_player == null or camera == null:
		return
	var target: Vector3 = pm.active_player.global_position + Vector3.UP * look_height
	var desired := _desired_position(target)
	desired = _avoid_collision(target, desired, pm.active_player)
	var k: float = clampf(blend_speed * delta, 0.0, 1.0)
	var next := camera.global_position.lerp(desired, k)
	if next.distance_to(target) > 0.05:
		camera.look_at_from_position(next, target, Vector3.UP)

func _desired_position(target: Vector3) -> Vector3:
	var hd := distance * cos(_pitch)
	var off := Vector3(hd * sin(_yaw), distance * sin(_pitch), hd * cos(_yaw))
	return target + off

func _avoid_collision(target: Vector3, desired: Vector3, player: Node) -> Vector3:
	var space := get_world_3d().direct_space_state
	var dir := desired - target
	var dist := dir.length()
	if dist < 0.01:
		return desired
	dir /= dist
	var params := PhysicsRayQueryParameters3D.create(target, desired)
	var exclude := [player.get_rid()]
	params.exclude = exclude
	params.hit_from_inside = true
	params.collide_with_areas = false
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return desired
	var safe := maxf(hit.position.distance_to(target) - collision_margin, 0.3)
	return target + dir * safe