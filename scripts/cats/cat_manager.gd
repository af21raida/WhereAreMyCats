extends Node
## CatManager (Phase 7) — autoload that tracks the three hiding cats and their
## discovery state, and drives the cat follower chain.
##
## Responsibilities:
##   - Discover the Cat nodes (group "cat") placed in the world.
##   - Record each cat as found (via Cat.reveal()) and announce ONLY the cat's
##     own discovery line (e.g. "You found Bread!") — no counters, no "all found"
##     banner, no names that could hint at the others.
##   - After discovery, make each found cat follow the companion chain so the
##     group reads Female -> Male -> cat1 -> cat2 -> cat3 with reasonable spacing.
##     The Male continues following the female exactly as before.
##
## Only the female protagonist discovers cats (proximity uses her position;
## Ginger requires the female to open the cabinet).

signal cat_found(cat: Cat)

const CAT_GROUP := "cat"

var cats: Array[Cat] = []
var found_ids: Array[StringName] = []

func _ready() -> void:
	process_physics_priority = 0

## (Re)gather the cat nodes from the "cat" group. Called lazily and every frame
## until the world has spawned them, then held.
func refresh() -> void:
	cats.clear()
	for n in get_tree().get_nodes_in_group(CAT_GROUP):
		if n is Cat:
			cats.append(n)
	found_ids.clear()
	for c in cats:
		if c.found and not found_ids.has(c.cat_id):
			found_ids.append(c.cat_id)

func found_count() -> int:
	if cats.is_empty():
		refresh()
	var count := 0
	for c in cats:
		if c.found:
			count += 1
	return count

func total() -> int:
	if cats.is_empty():
		refresh()
	return cats.size()

func all_found() -> bool:
	return total() > 0 and found_count() >= total()

## Called by Cat.reveal(); records the discovery and announces ONLY the cat's own
## discovery line so the player's find is acknowledged without revealing anything.
## Idempotent.
func discover(cat: Cat) -> void:
	if cat == null or not cat.found:
		return
	if not found_ids.has(cat.cat_id):
		found_ids.append(cat.cat_id)
	cat_found.emit(cat)
	var mgr := get_tree().root.get_node_or_null("InteractionManager")
	if mgr != null and cat.discovery_text != "":
		mgr.announce(cat.discovery_text, 2.5)

func _physics_process(_delta: float) -> void:
	if cats.is_empty():
		refresh()
		# Refresh may still be empty if the world hasn't spawned yet.
		if cats.is_empty():
			return
	_update_follow_chain()

## Makes each found cat follow the companion ahead in the chain (the male, then
## the previously-found cat). Every cat gets its OWN follow point — the companion
## ahead's position with a small per-cat lateral spread — so targets stay distinct
## while the whole group converges onto the same walkable surface (no trailing
## point that can end up hovering over the slope just below the landing, which
## previously stalled cats mid-ramp). The cat's own follow_gap/recoil keeps the
## actual spacing between bodies.
func _update_follow_chain() -> void:
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm == null or pm.active_player == null:
		return
	var prev: Node3D = _find_male(pm)
	if prev == null:
		prev = pm.active_player
	for i in range(cats.size()):
		var c: Cat = cats[i]
		if c == null or not c.found:
			continue
		c.follow_target = _anchor_point(c, prev.global_position, i)
		prev = c

## The follow point for `cat` (`index` selects the lateral spread): the companion
## ahead's standing spot nudged sideways, then Y-snapped to the walkable surface
## right under it. The snap keeps a target from floating in mid-air above a slope
## or crest edge, which made cats hover on the ramp instead of cresting onto the
## landing. Height is only snapped when the surface is within one step of the
## group's level (i.e. a normal slope); anything else (walls, a full floor down)
## is left at the companion's own height to avoid targeting into a wall.
func _anchor_point(cat: Cat, ahead: Vector3, index: int) -> Vector3:
	var side := 0.45 if index % 2 == 0 else -0.45
	var target := ahead + Vector3(side, 0.0, 0.0)
	var from := Vector3(target.x, ahead.y + 2.0, target.z)
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 12.0, 1)
	var hit := get_tree().root.world_3d.direct_space_state.intersect_ray(query)
	target.y = ahead.y
	if not hit.is_empty():
		var ground: float = (hit["position"] as Vector3).y
		if ground < ahead.y + 0.5 and ground > ahead.y - 1.2:
			target.y = ground + 0.02
	return target

func _find_male(pm: Node) -> Node3D:
	for p in get_tree().get_nodes_in_group("player"):
		if p is PlayerController and p != pm.active_player:
			return p
	return null

## Short summary for debugging / tests.
func summary() -> String:
	return "%d/%d found" % [found_count(), total()]