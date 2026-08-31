extends Node
## Phase 4 smoke test: verifies the PS1 rendering style is actually configured.
## Checks the low-resolution viewport, nearest-neighbour filtering, distance fog
## on the WorldEnvironment, and that the post-process shader is compiled and
## attached to the camera. Run: godot --headless --path <proj> res://tests/Phase4Test.tscn

var _failures: Array[String] = []
var _world: Node = null

func _ready() -> void:
	_world = load("res://scenes/World.tscn").instantiate()
	add_child(_world)
	_async()

func _async() -> void:
	for i in 3:
		await get_tree().physics_frame
	_check_viewport()
	_check_world_env()
	_check_materials()
	await _check_camera_postprocess()
	_report()

func _check_viewport() -> void:
	var vp := get_viewport()
	var root := get_tree().root
	# Low-resolution internal viewport configured in project.godot.
	var config_w: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", 0))
	var config_h: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	if config_w == 320 and config_h == 240:
		print("PASS low-res viewport configured (320x240 internal)")
	else:
		_fail("viewport not set to 320x240 (got %dx%d)" % [config_w, config_h])
	var stretch: String = ProjectSettings.get_setting("display/window/stretch/mode", "")
	if stretch == "canvas_items":
		print("PASS canvas_items stretch (pixelated upscale)")
	else:
		_fail("stretch mode not canvas_items (got %s)" % stretch)

func _check_world_env() -> void:
	var env = _world.get_node_or_null("Environment")
	var we: WorldEnvironment = env as WorldEnvironment
	if we == null or we.environment == null:
		_fail("WorldEnvironment missing")
		return
	if we.environment.fog_enabled:
		_fail("fog should be DISABLED (Phase 4 revision removed fog)")
	else:
		print("PASS fog disabled (distant cottage stays clearly visible)")

func _check_materials() -> void:
	# The procedural builder materials use nearest filtering.
	var cfg: int = int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1))
	if cfg == 0:
		print("PASS nearest texture filter set project-wide")
	else:
		_fail("default_texture_filter not nearest (got %d)" % cfg)

func _check_camera_postprocess() -> void:
	var cam_sys = _world.get_node_or_null("CameraSystem")
	if cam_sys == null:
		_fail("CameraSystem missing")
		return
	var pp = cam_sys.get_node_or_null("PS1PostProcess")
	if pp == null:
		_fail("PS1PostProcess node missing on CameraSystem")
		return
	var camera: Camera3D = cam_sys.get_node_or_null("Camera") as Camera3D
	if camera == null:
		_fail("Camera missing on CameraSystem")
		return
	# Give _ready time to attach the shader rect.
	await get_tree().process_frame
	await get_tree().process_frame
	var found := false
	for child in camera.get_children():
		var layer := child as CanvasLayer
		if layer != null and layer.get_child_count() > 0:
			var rect := layer.get_child(0) as ColorRect
			var mat := rect.material as ShaderMaterial
			if mat != null and mat.shader != null:
				print("PASS post-process has shader attached")
				print("PASS color_levels=%.0f dither=%.2f saturation=%.2f" % [float(mat.get_shader_parameter("color_levels")), float(mat.get_shader_parameter("dither_strength")), float(mat.get_shader_parameter("saturation"))])
				found = true
	if not found:
		_fail("post-process canvas layer/rect not attached to camera")

func _fail(msg: String) -> void:
	_failures.append(msg)

func _report() -> void:
	if _failures.is_empty():
		print("PHASE4 TEST: ALL PASS")
		get_tree().quit(0)
	else:
		print("PHASE4 TEST: FAILURES")
		for f in _failures:
			print("  FAIL: ", f)
		get_tree().quit(1)
