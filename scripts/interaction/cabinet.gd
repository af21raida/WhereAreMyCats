class_name InteractableCabinet
extends Interactable
## An interactive swing-door cabinet (Phase 6). Used for the kitchen cabinet that
## will be Ginger's hiding spot (Phase 7/8). A visible panel swings open/closed;
## the interior is a fixed box. Defaults to CLOSED (a cabinet you open to look
## inside).

@export var panel_size := Vector3(0.7, 0.9, 0.06)
@export var swing_from: Vector3 = Vector3.ZERO
@export var panel_color := Color(0.5, 0.38, 0.26)
@export var open_angle_deg := 110.0
@export var speed := 6.0

var is_open: bool = false
var _target_deg: float = 0.0
var _hinge: Node3D
var _degrad := 0.0

func setup_cabinet(center: Vector3, hinge_offset: Vector3) -> void:
	position = center
	swing_from = hinge_offset

func _configure() -> void:
	_add_trigger(Vector3.ZERO, panel_size + Vector3(0.7, 0.7, 0.7))
	_hinge = Node3D.new()
	_hinge.position = swing_from
	add_child(_hinge)
	_mesh(_hinge, panel_size, Vector3(panel_size.x * 0.5, panel_size.y * 0.5, 0.0), panel_color)

func _ready() -> void:
	super._ready()
	_configure()
	_target_deg = open_angle_deg if is_open else 0.0
	_degrad = _target_deg
	_hinge.rotation.y = deg_to_rad(_degrad)
	_update_prompt()

## The kitchen cabinet hides a cat, so it intentionally shows NO prompt text: the
## player is meant to open it through exploration, not because a hint told them
## to. Opening/closing still works normally on E.
func prompt_text() -> String:
	return ""

func _update_prompt() -> void:
	prompt = prompt_text()

func interact(_actor: Node3D) -> void:
	is_open = not is_open
	_target_deg = 0.0 if is_open else open_angle_deg
	_update_prompt()
	set_process(true)
	super.interact(_actor)

func _process(delta: float) -> void:
	if _hinge == null:
		return
	_degrad = lerpf(_degrad, _target_deg, clampf(speed * delta, 0.0, 1.0))
	_hinge.rotation.y = deg_to_rad(_degrad)
	if absf(_degrad - _target_deg) < 0.5:
		_degrad = _target_deg
		_hinge.rotation.y = deg_to_rad(_degrad)
		set_process(false)
