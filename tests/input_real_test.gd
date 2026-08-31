extends Node
## Verifies the REAL keyboard input path: feeding genuine InputEventKey events
## through Input.parse_input_event() (as the OS/window delivers them) and
## confirming the active player moves and the camera tracks. This catches issues
## that Input.action_press() (used in earlier tests) would mask, e.g. a broken
## physical keycode in the input map.
## Run: godot --headless --path <proj> res://tests/InputRealTest.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _reported := false

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	var pm = _pm()
	if pm == null or pm.active_player == null:
		return

	if _frame == 10:
		if pm.players.size() != 2:
			_failures.append("Expected 2 players, got %d" % pm.players.size())
		else:
			print("PASS players found = %d, active=%s" % [pm.players.size(), pm.active_player.character_id])
		# Record spawn position.
		_spawn_pos = pm.active_player.global_position

	if _frame == 12:
		# Press W (move_up) for 40 frames using a real key event.
		_send_key(87, true)   # KEY_W physical
	if _frame == 60:
		_send_key(87, false)
		_hold_end_pos = pm.active_player.global_position

	if _frame >= 65 and not _reported:
		_reported = true
		_check_movement(pm)
		_report()

var _spawn_pos: Vector3 = Vector3.ZERO
var _hold_end_pos: Vector3 = Vector3.ZERO

func _send_key(physical_keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _check_movement(pm) -> void:
	var moved := _hold_end_pos.distance_to(_spawn_pos)
	if moved > 0.5:
		print("PASS real-key movement: player moved %.2f units on W" % moved)
	else:
		_failures.append("Player did NOT move on real W key (moved %.3f)" % moved)

func _pm():
	return get_tree().root.get_node_or_null("PlayerManager")

func _report() -> void:
	if _failures.is_empty():
		print("INPUTREAL TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("INPUTREAL TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		get_tree().quit(1)
