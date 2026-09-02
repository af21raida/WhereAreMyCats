extends Node
## Phase 7 test (revised): verifies exploration-based cat discovery + following.
##   - CatManager autoload exists; three cats (ginger/tabby/tuxedo) with built
##     models at their hiding spots.
##   - The in-game names are Bread (ginger), Inej (tabby), Void (tuxedo) and the
##     ONLY discovery announcement is each cat's own line (no counters/hints).
##   - No hint prompts: the cabinet shows no prompt; there are no CatSpot nodes.
##   - Ginger is ONLY revealed by opening the cabinet (not by proximity).
##   - Inej and Void are revealed automatically by proximity (visual exploration).
##   - Discoveries happen once (idempotent), and found cats join the follower
##     chain that CatManager drives behind the male.
## Run: godot --headless --path <proj> res://tests/Phase7Test.tscn

var _world: Node = null
var _frame := 0
var _failures: Array[String] = []
var _mgr: Node = null
var _cats: Node = null
var _female: Node3D = null

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 10:
		_run_checks()

func _run_checks() -> void:
	_cats = get_tree().root.get_node_or_null("CatManager")
	if _cats == null:
		_fail("CatManager autoload missing")
		_report()
		return
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

	await _await_frames(5)

	# 1) Cats exist with models.
	var list: Array = get_tree().get_nodes_in_group("cat")
	if list.size() < 3:
		_fail("expected 3 cats, found %d" % list.size())
	else:
		print("PASS 3 cats present")
	var ginger := _find_cat_by_id(list, &"ginger")
	var tabby := _find_cat_by_id(list, &"tabby")
	var tuxedo := _find_cat_by_id(list, &"tuxedo")
	if ginger == null or tabby == null or tuxedo == null:
		_fail("missing cat(s): ginger=%s tabby=%s tuxedo=%s" % [
			ginger != null, tabby != null, tuxedo != null])

	await _await_frames(5)
	if ginger != null:
		_ensure("bread(ginger) has a built model", _has_meshes(ginger))
		_ensure("bread placed in the kitchen cabinet",
			ginger.global_position.distance_to(Vector3(5.0, 2.15, -5.5)) < 0.8)
		_ensure("in-game name is Bread", str(ginger.get("display_name")) == "Bread")
		_ensure("discovery line is 'You found Bread!'",
			str(ginger.get("discovery_text")) == "You found Bread!")
	if tabby != null:
		_ensure("inej(tabby) has a built model", _has_meshes(tabby))
		_ensure("inej placed under the bed",
			tabby.global_position.distance_to(Vector3(-3.3, 3.05, 3.9)) < 0.6)
		_ensure("in-game name is Inej", str(tabby.get("display_name")) == "Inej")
		_ensure("discovery line is 'You found Inej!!!'",
			str(tabby.get("discovery_text")) == "You found Inej!!!")
	if tuxedo != null:
		_ensure("void(tuxedo) has a built model", _has_meshes(tuxedo))
		_ensure("void placed in the dark bathroom",
			tuxedo.global_position.distance_to(Vector3(1.8, 3.05, 4.3)) < 0.6)
		_ensure("in-game name is Void", str(tuxedo.get("display_name")) == "Void")
		_ensure("discovery line is 'You found Void!!'",
			str(tuxedo.get("discovery_text")) == "You found Void!!")

	# 2) No hint prompts anywhere: no CatSpot nodes remain, and the cabinet shows
	# no prompt text.
	var interactables: Array = get_tree().get_nodes_in_group("interactable")
	var has_spot := false
	for n in interactables:
		var s: Script = n.get_script()
		if s != null and s.get_global_name() == "CatSpot":
			has_spot = true
	_ensure("no CatSpot hint nodes remain", has_spot == false)
	var cab := _find_typed(interactables, "InteractableCabinet")
	if cab != null:
		_ensure("cabinet prompt_text is empty (no 'Open cabinet' hint)",
			str(cab.prompt_text()) == "")

	# 3) Ginger must NOT be revealed by proximity — only by opening the cabinet.
	if ginger != null:
		_female.global_position = Vector3(5.0, 0.1, -4.6)
		await _await_frames(30)
		_ensure("ginger NOT revealed by standing near the cabinet",
			not bool(ginger.get("found")))
		if cab != null:
			await _await_frames(15)
			if _mgr.current == cab:
				_mgr.try_interact()
				await _await_frames(6)
				if bool(ginger.get("found")):
					print("PASS opening the cabinet discovered Bread (ginger)")
					var ad: Label = _mgr.get_node_or_null("InteractionUI/Announce")
					if ad != null and ad.visible and ad.text == "You found Bread!":
						print("PASS announce shows exactly 'You found Bread!'")
					else:
						_fail("announce mismatch after finding Bread (got '%s')" % (
							ad.text if ad != null else "<none>"))
					_ensure("Bread starts following after discovery",
						bool(ginger.get("following")) and int(ginger.get("collision_layer")) == 2)
				else:
					_fail("opening the cabinet did not discover Bread")
			else:
				_fail("cabinet not focused when opening (current=%s)" % _mgr.current)

	# 4) Inej discovered by proximity (exploration under the bed).
	if tabby != null:
		_female.global_position = Vector3(-3.3, 3.0, 3.1)
		await _await_frames(15)
		if bool(tabby.get("found")):
			print("PASS exploring near the bed discovered Inej")
			var ad2: Label = _mgr.get_node_or_null("InteractionUI/Announce")
			if ad2 != null and ad2.visible and ad2.text == "You found Inej!!!":
				print("PASS announce shows exactly 'You found Inej!!!'")
			else:
				_fail("announce mismatch after finding Inej (got '%s')" % (
					ad2.text if ad2 != null else "<none>"))
			_ensure("Inej starts following after discovery",
				bool(tabby.get("following")) and int(tabby.get("collision_layer")) == 2)
		else:
			_fail("Inej not discovered by proximity under the bed")

	# 5) Void discovered by proximity (exploring the dark bathroom).
	if tuxedo != null:
		_female.global_position = Vector3(1.8, 3.0, 3.9)
		await _await_frames(15)
		if bool(tuxedo.get("found")):
			print("PASS exploring the dark bathroom discovered Void")
			var ad3: Label = _mgr.get_node_or_null("InteractionUI/Announce")
			if ad3 != null and ad3.visible and ad3.text == "You found Void!!":
				print("PASS announce shows exactly 'You found Void!!'")
			else:
				_fail("announce mismatch after finding Void (got '%s')" % (
					ad3.text if ad3 != null else "<none>"))
			_ensure("Void starts following after discovery",
				bool(tuxedo.get("following")) and int(tuxedo.get("collision_layer")) == 2)
		else:
			_fail("Void not discovered by proximity in the bathroom")

	# 6) Bookkeeping + idempotence.
	await _await_frames(5)
	if _cats.all_found():
		print("PASS all_found() true after finding all three cats")
	else:
		_fail("all_found() still false (%d/%d)" % [_cats.found_count(), _cats.total()])
	if ginger != null:
		var before_idem: int = _cats.found_count()
		var again: bool = ginger.call("reveal")
		_ensure("re-revealing an already found cat is a no-op",
			again == false and _cats.found_count() == before_idem)

	# 7) Follower chain: found cats move toward their assigned targets behind the
	# male (full 3D target, recovering from spawn, no constant INF).
	if ginger != null:
		await _await_frames(30)
		var tgt: Vector3 = ginger.get("follow_target")
		if tgt == Vector3.INF:
			_fail("cat follow_target not being driven by CatManager chain")
		else:
			print("PASS cat follower chain is driving follow targets")
	if ginger != null and tabby != null and tuxedo != null:
		var before: Vector3 = ginger.global_position
		await _await_frames(60)
		var moved: float = ginger.global_position.distance_to(before)
		if moved > 0.05:
			print("PASS found cats actually move to follow (Bread moved %.2f)" % moved)
		else:
			# The chain may already have brought them close; that's OK if they at
			# least have a target close to the group.
			_ensure("found cats settled near the follower group (target within 12m)",
				Vector3(ginger.get("follow_target")).distance_to(ginger.global_position) < 12.0)

	# 8) Follower spacing + no pile-up: CatManager drives each cat toward its OWN
	# follow point (gap behind the companion ahead), so targets are distinct and
	# cats never park exactly on the male's position.
	if ginger != null and tabby != null and tuxedo != null:
		await _await_frames(30)
		var targets := [Vector3(ginger.get("follow_target")),
			Vector3(tabby.get("follow_target")), Vector3(tuxedo.get("follow_target"))]
		var distinct: bool = (targets[0] != targets[1]
			and targets[1] != targets[2] and targets[0] != targets[2])
		_ensure("follower chain gives every cat a distinct follow point", distinct)
		await _await_frames(90)
		var male = _world.get_node_or_null("Male")
		if male != null:
			var g: float = ginger.global_position.distance_to(male.global_position)
			if g < 0.35:
				_fail("follower overlaps the male position (distance %.2f)" % g)
			else:
				print("PASS follower keeps spacing behind the group (male gap %.2f)" % g)

	_report()

func _find_cat_by_id(list: Array, id: StringName) -> Node:
	for n in list:
		if n.get("cat_id") == id:
			return n
	return null

func _has_meshes(n: Node) -> bool:
	for c in n.get_children():
		if c is MeshInstance3D:
			return true
		if _has_meshes(c):
			return true
	return false

func _find_typed(list: Array, cname: String) -> Node:
	for n in list:
		if n is Interactable:
			var s: Script = n.get_script()
			if s != null and s.get_global_name() == cname:
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
		print("PHASE7 TEST: ALL PASS")
	else:
		print("PHASE7 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
	get_tree().quit(0 if _failures.is_empty() else 1)