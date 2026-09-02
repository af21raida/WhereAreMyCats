extends Node
## InteractionManager (Phase 6) — autoload that drives all player interactions.
##
## Responsibilities:
##   - Find the active (female) protagonist via PlayerManager.
##   - Each physics frame detect the nearest Interactable Area3D near the active
##     player and roughly in the camera's forward direction (the way she faces).
##   - Keep a `current` interactable and show a small prompt Label telling the
##     player what key does what.
##   - On the `interact` input edge (E / gamepad A), call `current.interact(player)`.
##   - `announce(msg, seconds)` shows a temporary message overlay (used by
##     Inspectable and, later, cat clues/UI).
##
## Only the active protagonist triggers interactions; the male follower never does.

signal focus_changed(interactable: Interactable)
signal interaction_triggered(interactable: Interactable)

const GROUP := "interactable"

@export var forward_dot_min := 0.15     # must face the object at least this much
var current: Interactable = null

# Feet height of the player capsule above its origin (CapsuleShape3D height 1.7
# in PlayerBase.tscn -> origin is the capsule centre, half-height 0.85).
const PLAYER_FEET_OFFSET := 0.85
# Feet height separating the ground floor (top ~0.1) from the upper floor
# (top ~3.0). A player mid-ramp is treated as being on whichever side.
const FLOOR_SPLIT_Y := 1.5

var _canvas: CanvasLayer
var _prompt: Label
var _announce: Label
var _announce_timer := 0.0
var _announce_msg := ""

func _ready() -> void:
	_build_ui()
	set_process(true)

func _process(delta: float) -> void:
	_update_announce(delta)

func _physics_process(_delta: float) -> void:
	var player := _active_player()
	var nearest := _find_nearest(player)
	_set_focus(nearest)
	if Input.is_action_just_pressed("interact"):
		try_interact()

## The female protagonist (or null if not yet ready).
func _active_player() -> Node3D:
	var pm := get_tree().root.get_node_or_null("PlayerManager")
	if pm == null or pm.active_player == null:
		return null
	return pm.active_player

## Which floor the player is standing on (matches Interactable.floor_level values):
## derived from the feet height so a player on the upper floor never interacts
## with ground-floor objects directly below them.
func _floor_level_of(player: Node3D) -> int:
	var feet := player.global_position.y - PLAYER_FEET_OFFSET
	return 1 if feet > FLOOR_SPLIT_Y else 0

func _find_nearest(player: Node3D) -> Interactable:
	if player == null:
		return null
	var cam := player.get_viewport().get_camera_3d()
	var player_level := _floor_level_of(player)
	var best: Interactable = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(GROUP):
		if not (n is Interactable) or not (n as Interactable).is_inside_tree():
			continue
		var it: Interactable = n as Interactable
		if it.floor_level != player_level:
			continue
		var to := it.global_position - player.global_position
		to.y = 0.0
		var horiz := to.length()
		if horiz > it.range_distance:
			continue
		# Facing check: in front of the player (camera-space forward).
		if cam != null:
			var fwd := -cam.global_transform.basis.z
			fwd.y = 0.0
			fwd = fwd.normalized()
			var dir := (it.global_position - player.global_position)
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.001 else Vector3.ZERO
			if dir != Vector3.ZERO and fwd.dot(dir) < forward_dot_min:
				continue
		if horiz < best_dist:
			best = it
			best_dist = horiz
	return best

func _set_focus(it: Interactable) -> void:
	if current == it:
		if current != null and current.is_inside_tree():
			return
		current = null
	_update_highlight(it)
	if it == null:
		_prompt.visible = false
		current = null
		return
	current = it
	var txt := it.prompt_text()
	if txt == "":
		# Some interactables are silent on purpose (e.g. the cabinet hiding a cat
		# must not announce "Open cabinet"): they still work, just show no hint.
		_prompt.visible = false
		_prompt.text = ""
	else:
		_prompt.visible = true
		_prompt.text = "[E] " + txt

func _update_highlight(it: Interactable) -> void:
	if current != null and current.is_inside_tree() and current != it:
		current.is_highlighted = false
	if it != null:
		it.is_highlighted = true

## Trigger the current interactable. Returns true if one was triggered.
func try_interact() -> bool:
	var it := current
	if it == null or not it.is_inside_tree():
		return false
	var player := _active_player()
	if player == null:
		return false
	it.interact(player)
	interaction_triggered.emit(it)
	# Refresh the prompt immediately so toggled prompts (Open/Close) update.
	var txt := it.prompt_text()
	if txt == "":
		_prompt.visible = false
		_prompt.text = ""
	else:
		_prompt.visible = true
		_prompt.text = "[E] " + txt
	return true

## Show a temporary message in the UI (used by Inspectable, later cat clues).
func announce(msg: String, seconds := 2.5) -> void:
	_announce_msg = msg
	_announce_timer = seconds
	_announce.visible = true
	_announce.text = msg

func _update_announce(delta: float) -> void:
	if _announce_timer <= 0.0:
		return
	_announce_timer -= delta
	if _announce_timer <= 0.0:
		_announce.visible = false
		_announce.text = ""

## Builds the prompt + announce UI (a minimal CanvasLayer; full UI overlays are
## Phase 10). Shown near screen-bottom under the PS1 low-res viewport.
func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "InteractionUI"
	add_child(_canvas)

	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.position = Vector2(10, 210)
	_prompt.text = ""
	_prompt.visible = false
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.visible = false
	_canvas.add_child(_prompt)

	_announce = Label.new()
	_announce.name = "Announce"
	_announce.position = Vector2(10, 120)
	_announce.text = ""
	_announce.visible = false
	_announce.add_theme_font_size_override("font_size", 22)
	_canvas.add_child(_announce)