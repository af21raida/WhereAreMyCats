class_name FixedCameraManager
extends Node3D
## Fixed-camera controller (Phase 2).
##
## Owns a single active Camera3D and, each frame, selects the CameraZone that
## currently contains the active (female) protagonist and smoothly blends the
## camera to that zone's composed view. When the player is in no zone (e.g.,
## an open exterior region), it falls back to a soft third-person framing so the
## camera never breaks.
##
## Because player movement is camera-relative (see PlayerController), switching
## between fixed views keeps controls intuitive: the direction keys always move
## relative to the on-screen camera.

@export var camera_path: NodePath
@export var zones: Array[NodePath] = []
@export var blend_speed := 6.0
@export var fallback_distance := 6.0
@export var fallback_height := 3.5
@export var look_height := 1.5
@export var zoom_step := 0.5
@export var zoom_in_max := 4.0
@export var zoom_out_max := 6.0

var _zones: Array[CameraZone] = []
var camera: Camera3D
var _zoom := 0.0

func _ready() -> void:
	if camera_path != NodePath():
		camera = get_node_or_null(camera_path) as Camera3D
	if camera != null:
		camera.current = true
	for path in zones:
		var node := get_node_or_null(path)
		if node is CameraZone:
			_zones.append(node)

func _process(delta: float) -> void:
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm == null or pm.active_player == null or camera == null:
		return
	var pos: Vector3 = pm.active_player.global_position
	var zone := _find_zone(pos)
	var desired_pos: Vector3
	var desired_look: Vector3
	if zone != null:
		desired_pos = zone.desired_position()
		desired_look = zone.desired_look()
	else:
		desired_pos = pos + Vector3(0.0, fallback_height, fallback_distance)
		desired_look = pos + Vector3.UP * look_height
	desired_pos = _apply_zoom(desired_pos, desired_look)
	_blend_to(desired_pos, desired_look, delta)

## Mouse-wheel zoom: scroll up dollys the camera in toward the view's look point,
## scroll down pulls it back out. Applied every frame on top of whatever view
## (zone or fallback) the manager is using.
func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom = clampf(_zoom + zoom_step, -zoom_out_max, zoom_in_max)
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom = clampf(_zoom - zoom_step, -zoom_out_max, zoom_in_max)

func _apply_zoom(desired_pos: Vector3, desired_look: Vector3) -> Vector3:
	var axis := desired_pos - desired_look
	if axis.length() < 0.001:
		return desired_pos
	var along := axis.normalized()
	# Never let zoom-in push the camera past the look point.
	var max_in := maxf(axis.length() - 0.4, 0.0)
	var d := minf(_zoom, max_in)
	return desired_pos - along * d

func _find_zone(pos: Vector3) -> CameraZone:
	var best: CameraZone = null
	for z in _zones:
		if z.contains_point(pos):
			if best == null or z.priority > best.priority:
				best = z
	return best

func _blend_to(desired_pos: Vector3, desired_look: Vector3, delta: float) -> void:
	var k: float = clamp(blend_speed * delta, 0.0, 1.0)
	camera.global_position = camera.global_position.lerp(desired_pos, k)

	var dir := desired_look - camera.global_position
	if dir.length() < 0.0001:
		return
	var desired_basis := Transform3D().looking_at(dir, Vector3.UP).basis
	var current_basis := camera.global_transform.basis
	var new_basis := current_basis.slerp(desired_basis, k)
	var t := camera.global_transform
	t.basis = new_basis
	camera.global_transform = t
