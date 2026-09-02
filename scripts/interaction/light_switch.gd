class_name InteractableSwitch
extends Interactable
## An interactive wall light switch (Phase 6). Toggling it turns a target light
## on/off. Used for the (intentionally broken) bathroom light that will make
## Tuxedo's hiding spot hard to find: the switch is present but the bathroom
## light stays off (dead) so the room is dark per the Phase 8 mechanic.
##
## The target light is not referenced by path (procedural node) — instead, at
## interact time the switch looks for lights in the `light_switch_group` group
## (default "bathroom_light") in the scene tree, so the light can live anywhere
## in the world (e.g. an OmniLight3D in World.tscn).

@export var panel_size := Vector3(0.18, 0.3, 0.05)
@export var switch_color := Color(0.9, 0.88, 0.8)
@export_range(0.0, 1.0) var on_tint := 0.95
@export var light_switch_group: StringName = &"bathroom_light"

var is_on: bool = false
var _visual: MeshInstance3D

func setup_switch(center: Vector3) -> void:
	position = center

func _ready() -> void:
	super._ready()
	_add_trigger(Vector3.ZERO, panel_size + Vector3(0.3, 0.3, 0.3))
	_visual = _mesh(self, panel_size, Vector3.ZERO, switch_color)
	_update_visual()
	_update_prompt()

func _all_lights() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(light_switch_group):
		if n is Light3D:
			out.append(n)
	return out

func prompt_text() -> String:
	return "Turn off light" if is_on else "Turn on light"

func _update_prompt() -> void:
	prompt = prompt_text()

func _update_visual() -> void:
	if _visual != null:
		var tinted := switch_color.lerp(Color(1, 1, 0.5), 0.0)
		if is_on:
			tinted = Color(0.5, 0.4, 0.1).lerp(switch_color, on_tint)
		_visual.set_surface_override_material(0, _mat(tinted))

func interact(_actor: Node3D) -> void:
	var lights := _all_lights()
	if lights.is_empty():
		# No light wired up — still toggle state so the system is testable.
		is_on = not is_on
		_update_visual()
		_update_prompt()
		super.interact(_actor)
		return
	is_on = not is_on
	for l in lights:
		l.visible = is_on
	if not is_on:
		# A dead switch: when turned "on" nothing visibly lights up if desired.
		pass
	_update_visual()
	_update_prompt()
	super.interact(_actor)
