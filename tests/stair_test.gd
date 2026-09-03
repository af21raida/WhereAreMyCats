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

const FOOT := Vector3(0.0, 0.1, -2.2)        # ground floor at the foot of the stairs
const STAIR_TOP := Vector3(0.0, 3.0, -5.9)   # on the flat top of the ramp at the back
# Landing + room waypoints. Coming up the stairs the player crests at z=-5.2,
# walks north along the center landing (x -1.2..1.2), and the bedroom (LEFT,
# x<-1.2) and bathroom (RIGHT, x>1.2) doors sit in the dividing walls at x=±1.2.
const LAND_STEP := Vector3(0.0, 3.0, -4.5)   # just off the crest onto the center landing
const LAND_WALK := Vector3(0.0, 3.0, 0.0)    # along the center landing
const BEDDOOR_APR := Vector3(-0.5, 3.0, -2.0)  # landing side, south of the bedroom door gap
const BATHDOOR_APR := Vector3(0.5, 3.0, -2.0)  # landing side, south of the bathroom door gap
const BEDROOM_HEAD := Vector3(-3.0, 3.0, -1.0) # inside the bedroom, past the open door
const BEDROOM_DEEP := Vector3(-4.0, 3.0, 3.0) # deeper in the bedroom (clear of the bed)
const BATH_HEAD := Vector3(3.0, 3.0, -1.0)     # inside the bathroom, past the open door

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

	# 2b) Upstairs: the bedroom + bathroom doors hang closed in the dividing walls;
	# open both (as the player would) so the later walks stay physically clear.
	print("STAGE 2b: room doors (dividing walls) open")
	var bdoor: Node = _world.get_node_or_null("Cottage/BedroomDoor")
	var adoor: Node = _world.get_node_or_null("Cottage/BathroomDoor")
	if bdoor == null or adoor == null:
		_fail("BedroomDoor/BathroomDoor missing (dividing walls)")
	else:
		await _open_door(bdoor)
		await _open_door(adoor)
		await _await_frames(35)   # let the panels finish swinging clear

	# 3) Step off the top of the stairs onto the flat landing, walk north along
	# the center landing, then through the open bedroom door (LEFT) into the bedroom.
	print("STAGE 3: step onto landing -> bedroom (door LEFT)")
	await _walk_to(_female, LAND_STEP, 500)
	await _walk_to(_female, LAND_WALK, 500)
	await _walk_to(_female, BEDDOOR_APR, 500)
	await _walk_to(_female, BEDROOM_HEAD, 500)
	_check("reached the bedroom floor",
		absf(_female.global_position.y - 3.0) < 0.5,
		"pos=%s", _female.global_position)

	# 3b) From the bedroom walk east back through the bedroom door, across the
	# landing, and into the bathroom through its open door (RIGHT).
	print("STAGE 3b: bathroom door (RIGHT) entry is easy")
	await _walk_to(_female, BEDDOOR_APR, 300)
	await _walk_to(_female, BATHDOOR_APR, 300)
	await _walk_to(_female, BATH_HEAD, 500)
	_check("reached the bathroom floor through its open door",
		absf(_female.global_position.y - 3.0) < 0.5,
		"pos=%s", _female.global_position)

	# 4) Walk across the bedroom interior (clear of the bed).
	print("STAGE 4: walk across the bedroom")
	await _walk_to(_female, BATHDOOR_APR, 300)
	await _walk_to(_female, BEDDOOR_APR, 300)
	await _walk_to(_female, BEDROOM_HEAD, 300)
	await _walk_to(_female, BEDROOM_DEEP, 500)
	_check("stable bedroom floor",
		absf(_female.global_position.y - 3.0) < 0.5,
		"pos=%s", _female.global_position)

	# 5) Return to the stair head through the (open) bedroom door, then walk DOWN
	# to the ground.
	print("STAGE 5: back down to the ground floor")
	await _walk_to(_female, BEDROOM_HEAD, 400)
	await _walk_to(_female, BEDDOOR_APR, 400)
	await _walk_to(_female, LAND_WALK, 400)
	await _walk_to(_female, LAND_STEP, 400)
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

	# 9) Bug #2 regression: the male must NOT freeze when the female is on a
	# different floor directly (almost) above him. Arrival used to be checked
	# in the horizontal plane only, so he considered himself "arrived" whenever
	# the female was within 1.6 m in XZ even on another floor.
	print("STAGE 9: male keeps following when the female is on a different floor")
	await _check_follow_across_floors()

	# 10) Follower chain: once the cats are found they must (a) climb the ramp
	# ON THEIR OWN to the crest/landing, and (b) thread the open bedroom door by
	# walking through the dividing wall gap — collisions, not teleports, get them up.
	print("STAGE 10: cats climb up and thread the open bedroom door")
	await _check_cats_follow_up()

	# 11) The dividing walls really close off the rooms: pushing into the SOLID
	# dividing wall (beside the door gaps) must be blocked, and the stairwell railing
	# must stop a player straying sideways into the open pit — while the door gaps
	# themselves stay passable (stages 3/3b).
	print("STAGE 11: dividing walls + stairwell railing block passage")
	await _check_hallway_wall_blocks()

func _male_follows_up() -> void:
	if _male == null:
		_fail("Male missing")
		return
	_female.global_position = BEDROOM_DEEP
	_male.global_position = Vector3(0.0, 0.1, -1.6)
	await _walk_to(_male, STAIR_TOP, 1000)
	await _walk_to(_male, LAND_STEP, 500)
	await _walk_to(_male, LAND_WALK, 500)
	await _walk_to(_male, BEDDOOR_APR, 500)
	await _walk_to(_male, BEDROOM_HEAD, 500)
	_check("male followed up onto the landing and into the bedroom",
		absf(_male.global_position.y - 3.0) < 0.5,
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

func _check_follow_across_floors() -> void:
	if _male == null or _female == null:
		_fail("players missing for across-floors follow check")
		return
	# (a) LOGIC regression (Bug #2): park the male on the ground and the female
	# ONE FLOOR UP almost directly above him (horizontal gap ~0.1 m, vertical
	# gap ~2.9 m). Arrival used to be checked in the horizontal plane only, so
	# he considered himself "arrived" and froze below her. With the full-3D
	# arrival check the follower must still steer (wish != 0) while the 3D gap
	# is above his stop distance.
	_male.global_position = Vector3(0.0, 0.1, -1.6)
	_female.global_position = Vector3(0.0, 3.0, -1.5)
	await _await_frames(8)
	var target_pos := _female.global_position
	var gap3d: float = _male.global_position.distance_to(target_pos)
	var pc := _male as PlayerController
	var wish := Vector3.ZERO
	if pc != null:
		wish = pc._read_follow_direction()
	_check("male follower still steering at another floor (horizontal-only stop would freeze him)",
		gap3d > 1.6 and wish.length() > 0.1,
		"gap3d=%.2f wish=%.2f", gap3d, wish.length())

	# (b) BEHAVIOUR: give the chase a real horizontal run — female on the upper
	# landing strip ahead of the male, who must actively close the horizontal gap
	# (the stairs are behind him; even a wrong-headed dash proves he did not park).
	_male.global_position = Vector3(0.0, 0.1, -1.6)
	_female.global_position = Vector3(0.0, 3.0, 0.6)
	await _await_frames(8)
	var fxz := Vector2(_female.global_position.x, _female.global_position.z)
	var start := Vector2(_male.global_position.x, _male.global_position.z)
	var flat_start: float = start.distance_to(fxz)
	for i in 50:
		await get_tree().physics_frame
	var end := Vector2(_male.global_position.x, _male.global_position.z)
	var moved: float = end.distance_to(start)
	var flat_end: float = end.distance_to(fxz)
	if moved > 0.5 and flat_end < flat_start:
		print("PASS male keeps pursuing the female on another floor (moved %.2f m, closed %.2f -> %.2f)" %
			[moved, flat_start, flat_end])
	else:
		_fail("male froze when the female was on the upper floor (moved %.2f m, flat %.2f -> %.2f)" %
			[moved, flat_start, flat_end])

func _check_hallway_wall_blocks() -> void:
	# Park the female on the center landing, then push EAST at z=-3.0 — straight
	# into the SOLID east dividing wall (x=1.2). She must be stopped, i.e. her x
	# stays < 1.1; only the door gap at z=-1.0 passes.
	_female.global_position = Vector3(0.0, 3.0, -3.0)
	for i in 10:
		await get_tree().physics_frame
	await _walk_to(_female, Vector3(3.0, 3.0, -3.0), 240)
	if _female.global_position.x < 1.1:
		print("PASS east dividing wall blocks passage (x=%.2f)" % _female.global_position.x)
	else:
		_fail("walked through the east dividing wall (x=%.2f)" % _female.global_position.x)

	# The stairwell pit is guarded by the dividing walls at x=±1.2 and the front
	# railing at z=-2.0. Pushing SOUTH from the landing at x=0.0 must be stopped
	# by the railing, so the female's z stays > -2.1: she may not reach the open
	# pit below.
	_female.global_position = Vector3(0.0, 3.0, -1.5)
	for i in 10:
		await get_tree().physics_frame
	await _walk_to(_female, Vector3(0.0, 3.0, -3.5), 240)
	if _female.global_position.z > -2.1:
		print("PASS stairwell railing blocks passage into the pit (z=%.2f)" % _female.global_position.z)
	else:
		_fail("walked past the stairwell railing into the pit (z=%.2f)" % _female.global_position.z)

func _check_cats_follow_up() -> void:
	if _male == null or _female == null:
		_fail("players missing for the cat follow-up check")
		return
	for c in get_tree().get_nodes_in_group("cat"):
		if c is Cat:
			c.reveal()
	# Both room doors are already open (stage 2b). Park the group at the TOP of
	# the stairs and the cats at the base of the ramp.
	_female.global_position = STAIR_TOP
	_male.global_position = STAIR_TOP
	for c in get_tree().get_nodes_in_group("cat"):
		var cat3 := c as Node3D
		cat3.global_position = Vector3(0.0, 0.1, -1.4)
	await _await_frames(10)
	# PHASE A — the cats must climb the ramp ON THEIR OWN (the anchors sit at the
	# stair top, due south of them) and reach the crest/landing. Nothing may
	# teleport them up; only collision and gravity.
	var climb_passes := 0
	for i in 680:
		await get_tree().physics_frame
		if i % 20 == 0 and _cat_on_upper_floor():
			climb_passes += 1
	if climb_passes >= 3:
		print("PASS cats climbed the staircase on their own")
	else:
		_fail("no cat climbed the staircase (climb_passes=%d)" % climb_passes)
	# PHASE B — door-threading: the male perches just inside the (open) bedroom
	# door, the female idles 1 m north of him (inside his follow-stop, so he stays
	# put), and the cats start on the landing south of the gap. The only way into
	# the bedroom is the 1.3 m-wide doorway in the west dividing wall, so each cat
	# must walk straight through it to reach his perch — nothing can teleport them
	# into the bedroom.
	_male.global_position = BEDROOM_HEAD
	_female.global_position = BEDROOM_HEAD + Vector3(0.0, 0.0, 1.0)
	var cat_slots: Array[Vector3] = [
		Vector3(-0.5, 3.0, -2.5),
		Vector3(-1.0, 3.0, -2.5),
		Vector3(0.0, 3.0, -2.5),
	]
	var k := 0
	for c in get_tree().get_nodes_in_group("cat"):
		if c is Cat:
			var cat3 := c as Node3D
			if k < cat_slots.size():
				cat3.global_position = cat_slots[k]
			k += 1
	await _await_frames(10)
	var door_passes := 0
	for i in 1200:
		await get_tree().physics_frame
		if i % 20 == 0 and _cat_past_door():
			door_passes += 1
	if door_passes >= 5:
		print("PASS at least one cat threaded the open bedroom door on its own")
	else:
		_fail("no cat passed through the open bedroom door (door_passes=%d)" % door_passes)

func _cat_on_upper_floor() -> bool:
	# The crest/flat-top of the ramp walks LEVEL with the landing, but the cat
	# capsule's origin settles ~0.2 m toward the slope, so "upstairs" is reached
	# once a cat clears half the rise (y>2.5 can only happen past the shaft maw,
	# z<-5.4, i.e. AT the top band). y>2.9 never (and never will) fire here.
	for c in get_tree().get_nodes_in_group("cat"):
		if (c as Node3D).global_position.y > 2.5:
			return true
	return false

func _cat_past_door() -> bool:
	for c in get_tree().get_nodes_in_group("cat"):
		if (c as Node3D).global_position.x < -1.2:
			return true
	return false

func _open_door(d: Node) -> void:
	_check("%s defaults closed" % d.name, bool(d.get("is_open")) == false,
		"open=%s", d.get("is_open"))
	d.call("interact", _female)
	_check("%s opens on interact" % d.name,
		bool(d.get("is_open")) == true, "open=%s", d.get("is_open"))

func _await_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

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
