extends Node
## Stair regression test: verifies the staircase is a real, walkable path between
## the ground floor and upstairs using the same CharacterBody3D move_and_slide /
## gravity movement as the player controller.
##
## The staircase rises in the back-center. Realistic head-on use: walk from the
## living room to the stair foot, climb UP the ramp head-on, step off the top onto
## the upstairs bedroom, walk the bedroom, then step back onto the ramp and walk
## DOWN to the ground floor. Also: male follower follows up head-on behind the
## female, the fixed camera frames the player near the stairs, and the walls around
## the stairs block passage.
## Run: godot --headless --path <proj> res://tests/StairTest.tscn

const FOOT := Vector3(0.0, 0.1, -2.2)   # ground floor at the foot of the stairs
const STAIR_TOP := Vector3(0.0, 3.0, -5.9)  # on the flat top of the ramp at the back
const BEDROOM_HEAD := Vector3(-2.0, 3.0, -5.9)  # upstairs bedroom at the stair head

var _world: Node = null
var _failures: Array[String] = []
var _female: CharacterBody3D = null
var _male: CharacterBody3D = null

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)
	_runner()

func _runner() -> void:
	for i in 3:
		await get_tree().physics_frame
	_female = _world.get_node_or_null("Female")
	_male = _world.get_node_or_null("Male")
	await _main()
	await _report()

func _main() -> void:
	if _female == null:
		_fail("Female missing")
		return

	# 1) Walk from the living room to the foot of the stairs (ground floor).
	print("STAGE 1: living room -> stair foot")
	_female.global_position = Vector3(-3.0, 0.1, 1.5)
	await _walk_to(_female, FOOT, 700)
	_check("reached stair foot on ground floor",
		_female.global_position.distance_to(FOOT) < 0.6 and absf(_female.global_position.y - 0.1) < 0.5,
		"pos=%s", _female.global_position)

	# 2) Climb UP the staircase (head-on).
	print("STAGE 2: climb up the stairs")
	await _walk_to(_female, STAIR_TOP, 900)
	_check("climbed up the staircase to the top",
		_female.global_position.y >= 2.4,
		"pos=%s", _female.global_position)

	# 3) Step off the top of the stairs onto the upstairs bedroom.
	print("STAGE 3: step onto upstairs bedroom")
	await _walk_to(_female, BEDROOM_HEAD, 500)
	_check("reached upstairs bedroom floor",
		absf(_female.global_position.y - 3.0) < 0.5,
		"pos=%s", _female.global_position)

	# 4) Walk across the upper floor (bedroom) to confirm a stable upper-floor floor.
	print("STAGE 4: walk across the upper floor")
	await _walk_to(_female, Vector3(-3.5, 3.0, 2.0), 900)
	_check("stable upper-floor floor",
		absf(_female.global_position.y - 3.0) < 0.5,
		"pos=%s", _female.global_position)

	# 5) Return to the stair head, step onto the ramp, and walk DOWN to the ground.
	print("STAGE 5: back down to the ground floor")
	await _walk_to(_female, BEDROOM_HEAD, 900)
	await _walk_to(_female, STAIR_TOP, 400)
	await _walk_to(_female, FOOT, 900)
	_check("walked back down to the ground floor",
		absf(_female.global_position.y - 0.1) < 0.5,
		"pos=%s", _female.global_position)

	# 6) Male follower climbs up (head-on) behind the female.
	print("STAGE 6: male follows up the stairs")
	await _male_follows_up()

	# 7) Fixed camera frames the player alongside the staircase.
	print("STAGE 7: camera framing on the staircase")
	await _check_camera_on_stairs()

	# 8) Walls around the stairs block the player.
	print("STAGE 8: walls around the stairs block passage")
	await _check_walls()

func _male_follows_up() -> void:
	if _male == null:
		_fail("Male missing")
		return
	_female.global_position = BEDROOM_HEAD
	_male.global_position = Vector3(0.0, 0.1, -1.6)
	await _walk_to(_male, STAIR_TOP, 1000)
	await _walk_to(_male, BEDROOM_HEAD, 500)
	_check("male followed up the staircase",
		_male.global_position.y >= 2.4,
		"male pos=%s", _male.global_position)

func _check_camera_on_stairs() -> void:
	var mng = _world.get_node_or_null("CameraSystem")
	if mng == null:
		_fail("CameraSystem missing")
		return
	_female.global_position = Vector3(0.0, 1.4, -3.5)
	for i in 40:
		await get_tree().physics_frame
	var dist: float = mng.camera.global_position.distance_to(_female.global_position + Vector3.UP * 1.5)
	if mng.camera.current and dist < 10.0 and dist > 0.3:
		print("PASS camera frames player on the staircase (dist=%.2f)" % dist)
	else:
		_fail("camera not framing on the staircase (dist=%.2f current=%s)" % [dist, mng.camera.current])

func _check_walls() -> void:
	# Player must not be able to push through the stairwell shaft side wall.
	_female.global_position = Vector3(0.0, 0.1, -3.0)
	for i in 10:
		await get_tree().physics_frame
	await _walk_to(_female, Vector3(-3.0, 0.1, -3.0), 200)
	if _female.global_position.x > -1.35:
		print("PASS left stair wall blocks passage (x=%.2f)" % _female.global_position.x)
	else:
		_fail("walked through the left stair wall (x=%.2f)" % _female.global_position.x)

func _check(what: String, cond: bool, fmt: String, a = null, b = null) -> void:
	if cond:
		print("PASS %s" % what)
	else:
		var vals: Array = []
		if a != null:
			vals.append(a)
		if b != null:
			vals.append(b)
		_failures.append("%s (%s)" % [what, fmt % vals])

func _walk_to(body: CharacterBody3D, target: Vector3, max_frames := 800) -> void:
	body.set_physics_process(false)
	var speed := 4.0
	var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	for f in max_frames:
		if body.global_position.distance_to(target) < 0.25:
			await get_tree().physics_frame
			body.set_physics_process(true)
			return
		var to := target - body.global_position
		to.y = 0.0
		var dir := Vector3.ZERO
		if to.length() > 0.01:
			dir = to.normalized()
		body.velocity = Vector3(dir.x * speed, 0.0, dir.z * speed)
		if body.is_on_floor():
			body.velocity.y = -0.5
		else:
			body.velocity.y -= grav * 0.016
		body.move_and_slide()
		await get_tree().physics_frame
	body.set_physics_process(true)

func _fail(msg: String) -> void:
	_failures.append(msg)

func _report() -> void:
	if _failures.is_empty():
		print("STAIR TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("STAIR TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		for i in 20:
			await get_tree().physics_frame
		get_tree().quit(1)
