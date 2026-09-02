class_name Inspectable
extends Interactable
## An inspectable object (Phase 6): interacting shows a short message. Used for
## small story/env props (notes, books, the fireplace, etc.). The message is shown
## by the InteractionManager's prompt/announce layer.

@export var message: String = ""
@export_range(0.5, 6.0) var show_seconds := 2.5

func _ready() -> void:
	super._ready()
	_add_trigger(Vector3.ZERO, Vector3(0.5, 0.7, 0.5))

func interact(_actor: Node3D) -> void:
	var mgr := get_tree().root.get_node_or_null("InteractionManager")
	if mgr != null and message != "":
		mgr.announce(message, show_seconds)
	super.interact(_actor)
