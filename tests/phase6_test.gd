extends Node
## Phase 6 test: verifies the Interaction System.
##   - InteractionManager autoload exists with prompt UI.
##   - Interactables exist in the cottage (door, cabinet, switch, inspectables).
##   - Near the female (facing), the manager focuses the right interactable and
##     shows the right prompt.
##   - `try_interact()` toggles state: front door opens/closes, cabinet opens,
##     bathroom light switch toggles the (broken/dark) bathroom light, inspectable
##     shows an announce message.
##   - The `interact` input action (E / gamepad A) is bound.
## Run: godot --headless --path <proj> res://tests/Phase6Test.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _mgr: Node = null
var _female: Node3D = null

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 10:
		_run_checks()

func _run_checks() -> void:
	_mgr = get_tree().root.get_node_or_null("InteractionManager")
	if _mgr == null:
		_fail("InteractionManager autoload missing")
		_report()
		return
	_female = _world.get_node_or_null("Female")
	if _female == null:
		_fail("Female missing")
		_report()
		return

	_ensure("interact input action bound", InputMap.has_action("interact"))

	# Count interactable groups in the world.
	var list: Array = get_tree().get_nodes_in_group("interactable")
	if list.size() < 6:
		_fail("expected >=6 interactables, got %d" % list.size())
	else:
		print("PASS interactables present (%d)" % list.size())

	var door := _find_floor_door(list, 0)
	var cab := _find_typed(list, "InteractableCabinet")
	var sw := _find_typed(list, "InteractableSwitch")
	var ins := _find_typed(list, "Inspectable")
	if door == null:
		_fail("front-door interactable missing")
	if cab == null:
		_fail("cabinet interactable missing")
	if sw == null:
		_fail("light-switch interactable missing")
	if ins == null:
		_fail("inspectable missing")

	# 1) Front door: player outside the door -> focus + toggle.
	await _await_frames(2)
	if door != null:
		await _focus_and_toggle(
			"door", door, Vector3(0.0, 0.1, 6.5),
			"Close door", "Open door", func(it):
				return (it as Object).get("is_open"))

	# 2) Kitchen cabinet (Phase 7): shows NO hint prompt, but still opens/closes
	# on E when the player is beside it (silent exploration discovery).
	if cab != null:
		_female.global_position = Vector3(5.0, 0.1, -4.7)
		await _await_frames(45)
		if _mgr.current == cab:
			print("PASS cabinet focused (ghost interactable)")
			var prompt: Label = _mgr.get_node_or_null("InteractionUI/Prompt")
			if prompt == null:
				_fail("cabinet: prompt UI missing")
			elif prompt.visible:
				_fail("cabinet: hint prompt must NOT be shown (Phase 7)")
			else:
				print("PASS cabinet shows no hint prompt")
			var before: bool = bool(cab.get("is_open"))
			_mgr.try_interact()
			await _await_frames(3)
			var after: bool = bool(cab.get("is_open"))
			if before != after:
				print("PASS cabinet toggled open/close (%s -> %s)" % [before, after])
			else:
				_fail("cabinet state did not change on interact")
		else:
			_fail("cabinet not focused when beside the counter (current=%s)" % _mgr.current)

	# 3) Bathroom light switch (upper floor): toggles the bathroom_light group.
	# Mounted on the bathroom's NORTH wall (facing into the room, south/-z), so
	# the player stands inside the bathroom below it and faces up the room.
	if sw != null:
		_orbit_camera(180.0)   # face the door/switch wall (+z ahead)
		await _focus_and_toggle(
			"bathroom light switch", sw, Vector3(5.4, 3.0, 3.3),
			"Turn on light", "Turn off light", func(_it):
				var ls := get_tree().get_nodes_in_group("bathroom_light")
				return ls.size() > 0 and (ls[0] as Node3D).visible)

		# 3b) Regression (Bug #1): standing deeper in the bathroom must focus the
		# SWITCH — the kitchen cabinet directly below on the ground floor must NOT
		# steal the prompt even though it is horizontally closer.
		_female.global_position = Vector3(5.0, 3.0, 3.4)
		await _await_frames(45)
		if _mgr.current == sw:
			print("PASS bathroom switch focused in bathroom (cabinet below not selected)")
		elif _mgr.current == cab:
			_fail("bug #1: kitchen cabinet stolen focus from the bathroom switch")
		else:
			_fail("bathroom switch not focused in bathroom (current=%s)" % _mgr.current)

	# 3c) Upstairs cross-wall: the bedroom (LEFT) + bathroom (RIGHT) doors are real
	# interactables on the upper floor, default CLOSED, side-by-side straight
	# ahead of the player at the top of the stairs. The player can focus and open
	# each one from the landing (the orbit camera lets her face the door wall).
	await _room_door_checks()

	# 4) Inspectable: fireplace -> announce message shows.
	if ins != null:
		await _await_frames(45)
		_female.global_position = Vector3(-4.0, 0.1, 5.7)
		await _await_frames(45)
		if _interact_current_is(ins):
			_mgr.try_interact()
			var ann: Label = _mgr.get_node_or_null("InteractionUI/Announce")
			if ann != null and ann.visible and ann.text.length() > 0:
				print("PASS inspectable shows announce message")
			else:
				_fail("inspectable announce not shown")
		else:
			_fail("inspectable not focused when near fireplace")

	_report()

func _room_door_checks() -> void:
	var bdoor: Node = _world.get_node_or_null("Cottage/BedroomDoor")
	var adoor: Node = _world.get_node_or_null("Cottage/BathroomDoor")
	if bdoor == null or adoor == null:
		_fail("upstairs room doors missing (bed=%s bath=%s)" % [bdoor != null, adoor != null])
		return
	# Structure: both are upper-floor interactables, closed by default.
	_ensure("bedroom door is an upper-floor interactable",
		int(bdoor.get("floor_level")) == 1 and bdoor is InteractableDoor)
	_ensure("bedroom door defaults closed", not bool(bdoor.get("is_open")))
	_ensure("bathroom door is an upper-floor interactable",
		int(adoor.get("floor_level")) == 1 and adoor is InteractableDoor)
	_ensure("bathroom door defaults closed", not bool(adoor.get("is_open")))

	# Bedroom door (LEFT): stand on the landing just south of it, orbit the camera
	# to face the door wall (yaw 180° = camera north looking south at the player,
	# with both doors straight ahead of her), focus + open.
	_orbit_camera(180.0)
	_female.global_position = Vector3(-1.2, 3.0, 0.7)
	await _await_frames(45)
	if _mgr.current != bdoor:
		_fail("bedroom door not focused from the landing (current=%s)" % _mgr.current)
	else:
		print("PASS bedroom door focused from the landing")
		var before: bool = bool(bdoor.get("is_open"))
		_mgr.try_interact()
		await _await_frames(3)
		var after: bool = bool(bdoor.get("is_open"))
		if before != after and after:
			print("PASS bedroom door opened by the player")
		else:
			_fail("bedroom door did not open on interact (%s -> %s)" % [before, after])

	# Bathroom door (RIGHT): same approach, opposite side of the nib.
	_female.global_position = Vector3(1.2, 3.0, 0.7)
	await _await_frames(45)
	if _mgr.current != adoor:
		_fail("bathroom door not focused from the landing (current=%s)" % _mgr.current)
	else:
		print("PASS bathroom door focused from the landing")
		var before: bool = bool(adoor.get("is_open"))
		_mgr.try_interact()
		await _await_frames(3)
		var after: bool = bool(adoor.get("is_open"))
		if before != after and after:
			print("PASS bathroom door opened by the player")
		else:
			_fail("bathroom door did not open on interact (%s -> %s)" % [before, after])

	# Reset the orbit so the later ground-floor inspectable uses the default view.
	_orbit_camera(0.0)

func _orbit_camera(deg: float) -> void:
	var mng = _world.get_node_or_null("CameraSystem")
	if mng == null:
		return
	mng._yaw = deg_to_rad(deg)

func _focus_and_toggle(label: String, it: Node, player_pos: Vector3,
		prompt_before: String, prompt_after: String, flag: Callable) -> void:
	_female.global_position = player_pos
	await _await_frames(45)
	if _mgr.current != it:
		_fail("%s not focused (current=%s at %s)" % [label, _mgr.current,
			_mgr.current.global_position if _mgr.current != null else "?"])
		return
	var prompt: Label = _mgr.get_node_or_null("InteractionUI/Prompt")
	if prompt == null:
		_fail("%s: prompt UI missing" % label)
		return
	if not prompt.visible:
		_fail("%s: prompt not visible when focused" % label)
		return
	if prompt.text != "[E] " + prompt_before:
		_fail("%s: prompt shows '%s', expected '[E] %s'" % [label, prompt.text, prompt_before])
		return
	print("PASS %s focused with prompt [E] %s" % [label, prompt_before])

	var before: bool = bool(flag.call(it)) if flag.is_valid() else false
	_mgr.try_interact()
	await _await_frames(3)
	if prompt.text != "[E] " + prompt_after:
		_fail("%s: prompt after toggle '%s', expected '[E] %s'" % [label, prompt.text, prompt_after])
		return
	var after: bool = bool(flag.call(it)) if flag.is_valid() else false
	if before == after:
		_fail("%s: state did not change on interact" % label)
		return
	print("PASS %s toggled (%s -> %s)" % [label, before, after])

func _interact_current_is(it: Node) -> bool:
	return _mgr.current != null and is_instance_valid(_mgr.current) and _mgr.current == it

func _find_typed(list: Array, cname: String) -> Node:
	for n in list:
		if n is Interactable:
			var s: Script = n.get_script()
			if s != null and s.get_global_name() == cname:
				return n
	return null

## Returns the first door on the requested floor (0 = ground, 1 = upstairs), so
## the front-door check always targets the entrance even though the upstairs room
## doors are also InteractableDoor nodes.
func _find_floor_door(list: Array, floor_level: int) -> Node:
	for n in list:
		if n is InteractableDoor:
			var s: Script = n.get_script()
			if s != null and s.get_global_name() == "InteractableDoor":
				if int(n.get("floor_level")) == floor_level:
					return n
	return null

func _await_frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _ensure(what: String, cond: bool) -> void:
	if cond:
		print("PASS %s" % what)
	else:
		_fail(what)

func _fail(msg: String) -> void:
	_failures.append(msg)

func _report() -> void:
	if _failures.is_empty():
		print("PHASE6 TEST: ALL PASS")
	else:
		print("PHASE6 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
	get_tree().quit(0 if _failures.is_empty() else 1)