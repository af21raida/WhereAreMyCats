class_name Interactable
extends Area3D
## Reusable interaction base for Phase 6.
##
## An interactable is an Area3D (a small trigger box) placed in the world that the
## InteractionManager detects when the active player is near and roughly facing it.
## Subclasses override `interact()` to perform the action (open/close a door,
## a cabinet, toggle a light switch, show an inspection message, ...). All
## interactables register in the "interactable" group so the manager can find them.
##
## Only the active protagonist (the female) triggers interactions; the male
## follower never does (see InteractionManager).

signal interaction_performed(interactable: Interactable)

@export var prompt: String = "Interact"
@export var range_distance: float = 2.2    # how close the player must be (meters)
## Which floor this interactable belongs to (0 = ground, 1 = upper, ...).
## The InteractionManager only lets the player focus an interactable whose
## floor_level matches the floor the player is currently standing on. This stops
## furniture on a different floor (e.g. the kitchen cabinet directly below the
## bathroom) from competing for focus just because it is horizontally close.
@export var floor_level: int = 0

var is_highlighted: bool = false
var _mat_cache: Dictionary = {}

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	set_process(false)

## Flat nearest-filtered material, matching the cottage's PS1 look.
func _mat(c: Color) -> StandardMaterial3D:
	if _mat_cache.has(c):
		return _mat_cache[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mat_cache[c] = m
	return m

## Helpers for subclasses to build a visual box (visual-only, no collision).
func _mesh(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)
	mi.set_surface_override_material(0, _mat(c))
	return mi

## Perform the interaction. `actor` is the interacting player (CharacterBody3D).
## Subclasses override this; the base just emits the signal.
func interact(_actor: Node3D) -> void:
	interaction_performed.emit(self)

## Text for the prompt that appears when this is the current focus. Subclasses may
## override to reflect state (e.g. "Open door" / "Close door").
func prompt_text() -> String:
	return prompt

## Build a small trigger CollisionShape3D (box) under this Area3D, positioned at
## `center` and sized `size`. Call from subclasses in _ready()/factory helpers.
func _add_trigger(center: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = size
	cs.shape = shp
	cs.position = center
	add_child(cs)
