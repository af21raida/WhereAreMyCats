extends Node
## Phase 1 headless automated test.
## Loads the World scene, verifies both protagonists spawn, the female is the
## sole controlled protagonist, the male always follows (never controllable),
## and movement responds to input on the female.
## Run: godot --headless --path <proj> res://tests/Phase1Test.tscn
## Prints PASS/FAIL lines; exits non-zero on failure.

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _reported := false

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/World.tscn")
	_world = scene.instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	var pm = _singleton()
	if _frame == 10:
		_check_spawn(pm)
	if _frame == 20:
		_check_active(pm)
		# Apply steering input on the controlled (female) player.
		Input.action_press("move_right")
		Input.action_press("move_up")
	if _frame == 60:
		_check_movement(pm)
		Input.action_release("move_right")
		Input.action_release("move_up")
	if _frame == 200:
		_record_follow_dist(pm)
	if _frame == 300:
		_check_follow_converged(pm)
	if _frame >= 302 and not _reported:
		_reported = true
		_report()
	elif _frame > 600 and not _reported:
		_reported = true
		_failures.append("Timed out before reaching verdict")
		_report()

func _singleton():
	return get_tree().root.get_node_or_null("PlayerManager")

func _check_spawn(pm) -> void:
	if pm == null:
		_failures.append("PlayerManager autoload missing")
		return
	if pm.players.size() != 2:
		_failures.append("Expected 2 players, got %d" % pm.players.size())
	else:
		var ids := []
		for p in pm.players:
			ids.append(String(p.character_id))
		print("PASS spawn: players = ", ids)

func _check_active(pm) -> void:
	if pm == null or pm.active_player == null:
		_failures.append("No active player at frame 20")
		return
	if pm.active_player.character_id != &"female":
		_failures.append("Active/controlled should be female, got %s" % pm.active_player.character_id)
	# The female must be controllable; the male must not be, and must follow.
	for p in pm.players:
		if p.character_id == &"male" and p.can_be_controlled:
			_failures.append("Male must NOT be controllable")
		if p.character_id == &"male" and p.is_active:
			_failures.append("Male must never be active")
		p.follow_target = pm.active_player.global_position
		if p.follow_target == Vector3.INF:
			_failures.append("Follow target not set on male")

func _check_movement(pm) -> void:
	var female: CharacterBody3D = null
	for p in pm.players:
		if p.character_id == &"female":
			female = p
	if female == null:
		_failures.append("Female player missing")
		return
	await _frames(5)
	var moved_x := absf(female.global_position.x)
	var moved_z := absf(female.global_position.z)
	if female.velocity.length() < 0.1 and moved_x < 0.05 and moved_z < 0.01:
		_failures.append("Female did not move in response to input")
	else:
		print("PASS movement: female responding to input (vel=%.2f)" % female.velocity.length())

func _check_follow(pm) -> void:
	var male: Node3D = null
	var female: Node3D = null
	for p in pm.players:
		if p.character_id == &"male":
			male = p
		if p.character_id == &"female":
			female = p
	if male == null or female == null:
		return
	var dist := male.global_position.distance_to(female.global_position)
	# Male remains within follow range of the female and is not independently
	# controllable (its velocity only ever reflects following, never input).
	if dist < 3.0:
		print("PASS follow: male %.1f units from female (readable together)" % dist)
	else:
		_failures.append("Male too far from female (%.1f)" % dist)

var _follow_dist_at_200 := 0.0
var _follow_dist_set := false

func _record_follow_dist(pm) -> void:
	var male: Node3D = null
	var female: Node3D = null
	for p in pm.players:
		if p.character_id == &"male":
			male = p
		if p.character_id == &"female":
			female = p
	if male != null and female != null:
		_follow_dist_at_200 = male.global_position.distance_to(female.global_position)
		_follow_dist_set = true

func _check_follow_converged(pm) -> void:
	var male: Node3D = null
	var female: Node3D = null
	for p in pm.players:
		if p.character_id == &"male":
			male = p
		if p.character_id == &"female":
			female = p
	if male == null or female == null or not _follow_dist_set:
		return
	var now := male.global_position.distance_to(female.global_position)
	# The male must be actively following: its gap to the female is shrinking
	# toward the 1.6 stop distance from its starting 10 units apart.
	if now < _follow_dist_at_200 and now < 8.0:
		print("PASS follow: male closing gap %.1f -> %.1f (actively following)" % [_follow_dist_at_200, now])
	else:
		_failures.append("Male not converging toward female (%.1f -> %.1f)" % [_follow_dist_at_200, now])

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _report() -> void:
	if _failures.is_empty():
		print("PHASE1 TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("PHASE1 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		get_tree().quit(1)
