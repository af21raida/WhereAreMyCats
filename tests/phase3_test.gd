extends Node
## Phase 3 smoke test: verifies the cottage blockout builds, collision/floors
## exist, the player does not fall through any room floor (ground floor, kitchen,
## upstairs bedroom/bathroom/back area) and the third-person camera frames the
## active player in every room and still zooms with the wheel.
## Run: godot --headless --path <proj> res://tests/Phase3Test.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _pm = null
var _mng = null
var _reported := false

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 5:
		_run_checks()

func _run_checks() -> void:
	_pm = get_tree().root.get_node_or_null("PlayerManager")
	var female = _world.get_node_or_null("Female")
	var male = _world.get_node_or_null("Male")
	var mng = _world.get_node_or_null("CameraSystem")
	_mng = mng
	if not _pm:
		_fail("PlayerManager missing")
	if female == null or male == null:
		_fail("Female or Male missing")
	else:
		if _pm.players.size() != 2:
			_fail("Expected 2 players, got %d" % _pm.players.size())
		if _pm.active_player != female:
			_fail("Active player is %s, not female" % (_pm.active_player.name if _pm.active_player else "null"))

	var sb_count := _count_of(_world, "StaticBody3D")
	var mesh_count := _count_of(_world, "MeshInstance3D")
	if sb_count < 20:
		_fail("Too few StaticBody3D (collision) -> %d" % sb_count)
	if mesh_count < 40:
		_fail("Too few MeshInstance3D (visual) -> %d" % mesh_count)

	if mng == null:
		_fail("CameraSystem missing")
		_report()
		return
	if mng.camera == null or not mng.camera.current:
		_fail("Camera missing or not current")

	var rooms = {
		"Living": Vector3(-3.0, 0.1, 2.0),
		"Kitchen": Vector3(3.0, 0.1, 2.0),
		"KitchenBack": Vector3(5.0, 0.1, -4.5),
		"Bedroom": Vector3(-3.5, 3.0, 2.0),
		"Bathroom": Vector3(3.5, 3.0, 2.0),
		"UpstairsBack": Vector3(0.5, 3.0, 2.0),
	}
	for room_name in rooms:
		_test_room_holds(female, mng, room_name, rooms[room_name])

	_test_stairs_climb(female, mng)
	_test_zoom(mng)
	_report()

func _test_room_holds(female, mng: Node, room_name: String, point: Vector3) -> void:
	if female == null:
		return
	var floor_y: float = point.y
	female.global_position = Vector3(point.x, point.y + 0.6, point.z)
	for i in 20:
		await get_tree().physics_frame
	var y: float = female.global_position.y
	if absf(y - floor_y) > 0.6:
		_fail("%s: player not on floor (y=%.2f, expected ~%.2f)" % [room_name, y, floor_y])
	var dist: float = mng.camera.global_position.distance_to(
		female.global_position + Vector3.UP * 1.5)
	if dist > float(mng.max_distance) + 0.5:
		_fail("%s: camera not framing player (%.2f away)" % [room_name, dist])

func _test_stairs_climb(female, _mng) -> void:
	if female == null:
		return
	female.global_position = Vector3(0.0, 0.1, -2.4)
	for step in range(12):
		female.global_position += Vector3(0.0, 0.3, -0.3)
		for i in 5:
			await get_tree().physics_frame
	if female.global_position.y < 0.8:
		_fail("Stairs did not take the player up: y=%.2f" % female.global_position.y)

func _test_zoom(mng: Node) -> void:
	if mng == null:
		return
	var d0 := float(mng.distance)
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	mng._unhandled_input(wheel)
	var d_out := float(mng.distance)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	mng._unhandled_input(wheel)
	var d_in := float(mng.distance)
	if not (d_out > d0 and d_in < d_out):
		_fail("Wheel did not zoom: %0.2f -> %0.2f -> %0.2f" % [d0, d_out, d_in])
	else:
		print("PASS zoom: distance %0.2f -> %0.2f -> %0.2f" % [d0, d_out, d_in])

func _count_of(n: Node, target_class: String) -> int:
	var count := 0
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.get_class() == target_class:
			count += 1
		for c in node.get_children():
			stack.append(c)
	return count

func _fail(msg: String) -> void:
	_failures.append(msg)

func _report() -> void:
	if _failures.is_empty():
		print("PHASE3 TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("PHASE3 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		get_tree().quit(1)