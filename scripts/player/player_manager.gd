extends Node
## Autoload manager that coordinates the two protagonists.
##
## Responsibilities:
##   - Discover both PlayerController characters (group "player").
##   - Make the female the single controlled protagonist; the male always
##     follows her and never receives player input (no switching).
##   - Point every non-controlled character at the female so they follow her.
##   - Expose `active_player` (the female) so the fixed camera can frame her.

var players: Array[PlayerController] = []
var active_player: PlayerController = null

## The character that the human always controls. The male is can_be_controlled
## = false and is never selected.
func is_controllable(p: PlayerController) -> bool:
	return p.can_be_controlled

func _ready() -> void:
	process_physics_priority = 0

## Gather player nodes. Called once they exist in the scene tree. The first
## controllable player (the female) becomes the active/controlled one; all
## others are followers.
func refresh() -> void:
	players.clear()
	for p in get_tree().get_nodes_in_group("player"):
		if p is PlayerController:
			players.append(p)
	if players.is_empty():
		return
	var target: PlayerController = null
	for p in players:
		if is_controllable(p):
			target = p
			break
	if target == null:
		target = players[0]
	for p in players:
		p.set_active(p == target)
	active_player = target

func _process(_delta: float) -> void:
	if players.is_empty():
		refresh()

func _physics_process(_delta: float) -> void:
	if players.is_empty():
		return
	_update_follow()

## Every non-controlled player follows the active (female) player.
func _update_follow() -> void:
	if active_player == null:
		return
	var target_pos := active_player.global_position
	for p in players:
		if p == active_player:
			continue
		p.follow_target = target_pos
