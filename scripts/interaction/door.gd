class_name InteractableDoor
extends Interactable
## An interactive hinged door (Phase 6). A panel pivots around a hinge edge so it
## swings open (rotated out of the doorway plane, passage remains open) or closed
## (lying in the doorway plane). Defaults to OPEN so the entrance stays a genuine
## open passage on startup; the player presses E/A to swing it open or closed.

@export var panel_size := Vector3(1.3, 2.15, 0.08)
@export var swing_from: Vector3 = Vector3.ZERO          # world offset of the hinge
@export var panel_color := Color(0.42, 0.3, 0.2)
@export var open_angle_deg := 100.0
@export var speed := 6.0

var is_open: bool = true
var _target_deg: float = 0.0
var _hinge: Node3D
var _degrad := 0.0

func setup_door(center: Vector3, hinge_offset: Vector3) -> void:
	position = center
	swing_from = hinge_offset
	is_open = true

func _configure() -> void:
	_add_trigger(Vector3.ZERO, panel_size + Vector3(0.6, 0.6, 0.6))
	_hinge = Node3D.new()
	_hinge.position = swing_from
	add_child(_hinge)
	# Panel hangs off the hinge so swinging it around Y pivots at the hinge edge.
	_mesh(_hinge, panel_size, Vector3(panel_size.x * 0.5, panel_size.y * 0.5, 0.0), panel_color)
	# The panel is ALSO a solid StaticBody3D under _hinge (it swings with the
	# visual). A closed door physically blocks players and followers; an open one
	# lies inside the room so the doorway stays a genuine passage. Default layer 1
	# = world, so the player, the male and the cats all collide with it.
	var body := StaticBody3D.new()
	body.name = "PanelSolid"
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = panel_size
	cs.shape = shp
	body.add_child(cs)
	body.position = Vector3(panel_size.x * 0.5, panel_size.y * 0.5, 0.0)
	_hinge.add_child(body)

func _ready() -> void:
	super._ready()
	_configure()
	_target_deg = open_angle_deg if is_open else 0.0
	_degrad = _target_deg
	_hinge.rotation.y = deg_to_rad(_degrad)
	_update_prompt()

func prompt_text() -> String:
	return "Close door" if is_open else "Open door"

func _update_prompt() -> void:
	prompt = prompt_text()

func interact(_actor: Node3D) -> void:
	is_open = not is_open
	_target_deg = open_angle_deg if is_open else 0.0
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
