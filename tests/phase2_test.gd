extends Node
## Phase 2 headless automated test for the follow camera, adapted for the
## third-person camera (which replaced the fixed-camera manager as the main
## camera). Verifies: camera setup/current, the camera frames the active (female)
## player from a working distance, it follows her when she moves/teleports, the
## mouse wheel zooms in/out, and the inactive male stays close (both readable
## together).
## Run: godot --headless --path <proj> res://tests/Phase2Test.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _reported := false
var _manager: Node = null

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	var pm = _pm()
	if pm == null:
		return
	if _frame == 10:
		_setup_refs(pm)
	if _frame == 20:
		_check_framing(pm)
	if _frame == 30:
		_check_zoom(pm)
	if _frame == 50:
		# Teleport the active player (female) to the kitchen; the camera should follow.
		pm.active_player.global_position = Vector3(3.0, 0.1, 2.0)
	if _frame == 100:
		_check_follow_camera(pm)
	if _frame == 130:
		# Reposition both characters in the open yard so follow steering is tested
		# on reachable ground (no wall nav obstacle). Male starts far behind.
		var female_node: Node3D = pm.active_player
		var male_node: Node3D = null
		for p in pm.players:
			if p != female_node:
				male_node = p
		if female_node != null:
			female_node.global_position = Vector3(0.0, 0.1, 8.0)
		if male_node != null:
			male_node.global_position = Vector3(0.0, 0.1, 12.0)
	if _frame == 230:
		_check_following(pm)
	if _frame >= 232 and not _reported:
		_reported = true
		_report()
	if _frame > 400 and not _reported:
		_reported = true
		_failures.append("Timed out before verdict")
		_report()

func _pm():
	return get_tree().root.get_node_or_null("PlayerManager")

func _distance_to_active(pm) -> float:
	return _manager.camera.global_position.distance_to(
		pm.active_player.global_position + Vector3.UP * 1.5)

func _setup_refs(pm) -> void:
	var mgr = _world.get_node_or_null("CameraSystem")
	if mgr == null:
		_failures.append("CameraSystem node missing")
		return
	_manager = mgr
	if mgr.camera == null:
		_failures.append("Manager has no camera")
	elif not mgr.camera.current:
		_failures.append("Managed camera is not current")
	else:
		print("PASS setup: camera current")

func _check_framing(pm) -> void:
	var dist := _distance_to_active(pm)
	if dist > float(_manager.max_distance) + 0.5 or dist < float(_manager.min_distance) - 0.5:
		_failures.append("Camera not framing player at working distance (%.2f)" % dist)
	else:
		print("PASS framing: camera %.2f from active player" % dist)

func _check_zoom(pm) -> void:
	var d0 := float(_manager.distance)
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	_manager._unhandled_input(wheel)
	var d_out := float(_manager.distance)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	_manager._unhandled_input(wheel)
	_manager._unhandled_input(wheel)
	var d_in := float(_manager.distance)
	if not (d_out > d0 and d_in < d_out):
		_failures.append("Wheel did not zoom out then in (%0.2f -> %0.2f -> %0.2f)" % [d0, d_out, d_in])
	else:
		print("PASS zoom: distance %0.2f -> %0.2f -> %0.2f" % [d0, d_out, d_in])

func _check_follow_camera(pm) -> void:
	var dist := _distance_to_active(pm)
	if dist > float(_manager.max_distance) + 0.5 or dist < float(_manager.min_distance) - 0.5:
		_failures.append("Camera did not follow player into kitchen (%.2f away)" % dist)
	else:
		print("PASS follow camera: framing player after teleport (%.2f)" % dist)

func _check_following(pm) -> void:
	var active: Node3D = pm.active_player
	var other: Node3D = null
	for p in pm.players:
		if p != active:
			other = p
	if other == null:
		_failures.append("No inactive player to check follow")
		return
	var dist := other.global_position.distance_to(active.global_position)
	if dist < 3.0:
		print("PASS following: inactive %.1f units from active (readable together)" % dist)
	else:
		_failures.append("Inactive player too far from active (%.1f)" % dist)

func _report() -> void:
	if _failures.is_empty():
		print("PHASE2 TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("PHASE2 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		get_tree().quit(1)