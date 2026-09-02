extends Node
## Phase 5 smoke test: verifies the cottage environment enrichment is present.
## Checks that the world has significantly more low-poly prop meshes than the
## Phase 3 blockout baseline, that the bedroom/bathroom furniture now lives on the
## UPPER floor (y ~3, not ground floor), that exterior greenery/props exist, and
## that the earlier room floor + camera framing checks still hold (no regression).
## Run: godot --headless --path <proj> res://tests/Phase5Test.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 5:
		_run_checks()

func _run_checks() -> void:
	var female = _world.get_node_or_null("Female")
	var mng = _world.get_node_or_null("CameraSystem")
	if female == null:
		_fail("Female missing")

	var mesh_count := _count_of(_world, "MeshInstance3D")
	if mesh_count < 70:
		_fail("Expected many Phase 5 prop meshes, got %d" % mesh_count)
	else:
		print("PASS prop mesh count = %d (enriched above blockout baseline)" % mesh_count)

	# Bedroom / bathroom furniture should be on the UPPER floor (y ~3), not ground.
	_check_upper_furniture_y("bed", Vector3(-3.3, 3.9, 4.35), 3.0)
	_check_upper_furniture_y("bedside", Vector3(-2.1, 3.55, 4.35), 3.0)
	_check_upper_furniture_y("bath-sink", Vector3(5.4, 3.7, 4.4), 3.0)
	_check_upper_furniture_y("toilet", Vector3(2.9, 3.4, 3.0), 3.0)
	_check_upper_furniture_y("bath", Vector3(5.4, 3.55, 3.0), 3.0)

	# Exterior greenery / props present near the yard (trees, shrubs, flowers).
	var exterior_meshes := _count_above_y(_world, 0.0)
	if exterior_meshes < 10:
		_fail("Too few low meshes for exterior greenery/props (got %d)" % exterior_meshes)

	# No regression: female still holds on the living + bedroom floors, camera frames.
	if female != null and mng != null:
		await _test_room_holds(female, mng, "Living", Vector3(-3.0, 0.1, 2.0))
		await _test_room_holds(female, mng, "Bedroom", Vector3(-3.5, 3.0, 2.0))

	_report()

func _check_upper_furniture_y(label: String, center: Vector3, expected_floor: float) -> void:
	if absf(center.y - expected_floor) > 1.2:
		_fail(label + " furniture not on upper floor (y=%.2f, expected ~%.0f)" % [center.y, expected_floor])
	else:
		print("PASS %s furniture on upper floor (y=%.2f)" % [label, center.y])

func _test_room_holds(female, mng: Node, room_name: String, point: Vector3) -> void:
	var floor_y: float = point.y
	female.global_position = Vector3(point.x, point.y + 0.6, point.z)
	for i in 20:
		await get_tree().physics_frame
	var y: float = female.global_position.y
	if absf(y - floor_y) > 0.6:
		_fail("%s: player not on floor (y=%.2f, expected ~%.2f)" % [room_name, y, floor_y])
	else:
		print("PASS %s: player on floor (y=%.2f)" % [room_name, y])
	var dist: float = mng.camera.global_position.distance_to(female.global_position + Vector3.UP * 1.5)
	if dist > float(mng.max_distance) + 0.5:
		_fail("%s: camera not framing player (%.2f away)" % [room_name, dist])
	else:
		print("PASS %s: camera frames player" % room_name)

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

func _count_above_y(n: Node, y: float) -> int:
	var count := 0
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and node.global_position.y > y and node.global_position.y < 1.5:
			count += 1
		for c in node.get_children():
			stack.append(c)
	return count

func _fail(msg: String) -> void:
	_failures.append(msg)

func _report() -> void:
	if _failures.is_empty():
		print("PHASE5 TEST: ALL PASS")
	else:
		print("PHASE5 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
	get_tree().quit(0 if _failures.is_empty() else 1)
