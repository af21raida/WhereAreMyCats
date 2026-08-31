class_name PS1PostProcess
extends Node3D
## Attaches a fullscreen post-process pass to the active camera that gives the
## rendered scene a PS1-style look: color quantization (reduced palette) and
## ordered dithering (Bayer 4x4). Works with the Compatibility renderer by
## reading SCREEN_TEXTURE in a canvas_item shader on a ColorRect inside a
## CanvasLayer parented to the camera.

@export var color_levels: float = 24.0
@export var dither_strength: float = 0.04
@export var saturation: float = 1.15

var _rect: ColorRect
var _shader: ShaderMaterial

func _ready() -> void:
	# Find the Camera3D sibling (set up by ThirdPersonCamera).
	var cam := _find_camera()
	if cam == null:
		return

	# CanvasLayer stays fixed on screen (doesn't move with the camera transform).
	var layer := CanvasLayer.new()
	layer.layer = 100
	cam.add_child(layer)

	# Full-screen ColorRect carrying the post-process shader.
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_rect)

	# Wait one frame so the viewport size is known, then size the rect.
	await get_tree().process_frame
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Shader material.
	var shader := load("res://shaders/ps1_post_process.gdshader") as Shader
	_shader = ShaderMaterial.new()
	_shader.shader = shader
	_shader.set_shader_parameter("color_levels", color_levels)
	_shader.set_shader_parameter("dither_strength", dither_strength)
	_shader.set_shader_parameter("saturation", saturation)
	_rect.material = _shader

func _find_camera() -> Camera3D:
	# Walk siblings to find a Camera3D (the ThirdPersonCamera setup puts it
	# as a child of the same parent Node3D).
	for sibling in get_parent().get_children():
		if sibling is Camera3D:
			return sibling
	# Check children (e.g., CameraSystem -> Camera).
	for child in get_parent().get_children():
		if child is Node3D:
			for grandchild in child.get_children():
				if grandchild is Camera3D:
					return grandchild
	return null
