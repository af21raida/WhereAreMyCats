class_name CameraZone
extends Node3D
## A fixed-camera zone.
##
## Represents one composed "room" view. A `trigger` (an Area3D whose child
## CollisionShape3D carries a BoxShape3D) defines the region in which the active
## player must stand for this zone to become the current camera. The `view`
## Camera3D defines the desired camera pose for the zone. An optional
## `look_target` node gives the point the camera should look at (otherwise the
## camera's own -Z is used).

@export var trigger_path: NodePath
@export var view_path: NodePath
@export var look_target_path: NodePath = NodePath()
@export var priority := 0

var trigger: Area3D
var trigger_shape: CollisionShape3D
var look_target: Node3D

func _ready() -> void:
	if trigger_path != NodePath():
		trigger = get_node_or_null(trigger_path) as Area3D
		if trigger != null:
			trigger_shape = trigger.get_node_or_null("Shape") as CollisionShape3D
	if look_target_path != NodePath():
		look_target = get_node_or_null(look_target_path) as Node3D

## True when the given world position lies inside the trigger box.
func contains_point(global_pos: Vector3) -> bool:
	if trigger == null or trigger_shape == null or not (trigger_shape.shape is BoxShape3D):
		return false
	var shape: BoxShape3D = trigger_shape.shape
	var local := trigger.global_transform.affine_inverse() * global_pos
	var half := shape.size * 0.5
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z

func desired_position() -> Vector3:
	if view_path == NodePath():
		return global_position
	var view := get_node_or_null(view_path) as Camera3D
	if view == null:
		return global_position
	return view.global_position

func desired_look() -> Vector3:
	if look_target != null:
		return look_target.global_position
	if view_path != NodePath():
		var view := get_node_or_null(view_path) as Camera3D
		if view != null:
			return view.global_position - view.global_transform.basis.z
	return global_position
