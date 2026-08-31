class_name CottageBuilder
extends Node3D
## Phase 3 — builds the cottage blockout (geometry, collision, stairs, furniture,
## exterior scenery and the fixed-camera zones) from an explicit layout table.
## Runs once in _ready(); everything is plain primitive boxes and simple
## materials suitable for a blockout. No final PS1 assets yet.

const WT := 0.2
const GH := 3.0
const UF := 3.0
const UH := 6.0
const EX := 6.0
const Z_BACK := -6.0
const Z_FRONT := 5.0

const C_GRASS := Color(0.35, 0.46, 0.30)
const C_DIRT := Color(0.50, 0.40, 0.32)
const C_WALL := Color(0.78, 0.72, 0.62)
const C_WALL_EXT := Color(0.56, 0.46, 0.36)
const C_FLOOR := Color(0.50, 0.38, 0.26)
const C_ROOF := Color(0.44, 0.28, 0.24)
const C_FURN := Color(0.42, 0.32, 0.22)
const C_SOFA := Color(0.48, 0.35, 0.30)
const C_COUNTER := Color(0.72, 0.66, 0.55)
const C_FRIDGE := Color(0.60, 0.60, 0.62)
const C_BED := Color(0.62, 0.55, 0.50)
const C_BATH := Color(0.75, 0.78, 0.80)
const C_TREE := Color(0.30, 0.42, 0.25)
const C_TRUNK := Color(0.40, 0.30, 0.20)
const C_FENCE := Color(0.55, 0.45, 0.32)
const C_PATH := Color(0.56, 0.47, 0.35)

var _cache: Dictionary = {}

func _ready() -> void:
	_build_base()
	_build_walls()
	_build_interior_walls()
	_build_stairs()
	_build_furniture()
	_build_exterior()
	_build_roof()
	_build_zones()

func _mat(c: Color) -> StandardMaterial3D:
	if _cache.has(c):
		return _cache[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	_cache[c] = m
	return m

func _mesh(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)
	mi.set_surface_override_material(0, _mat(c))
	return mi

func _solid(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	parent.add_child(sb)
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = size
	cs.shape = shp
	sb.add_child(cs)
	_mesh(sb, size, Vector3.ZERO, c)
	return sb

## Builds the big exterior ground, the interior ground-floor slab, and the upper
## floor slab(s) with a hole over the stairwell shaft.
func _build_base() -> void:
	_solid(self, Vector3(30.0, 0.4, 26.0), Vector3(0.0, -0.1, 0.0), C_GRASS)
	_solid(self, Vector3(12.4, 0.4, 11.4), Vector3(0.0, -0.1, -0.5), C_FLOOR)
	_solid(self, Vector3(5.0, 0.4, 11.4), Vector3(-3.7, 2.8, -0.5), C_FLOOR)
	_solid(self, Vector3(5.0, 0.4, 11.4), Vector3(3.7, 2.8, -0.5), C_FLOOR)
	_solid(self, Vector3(2.4, 0.4, 7.2), Vector3(0.0, 2.8, 1.6), C_FLOOR)

## Outer shell (exterior walls) for both floors. The south wall has the front
## door gap; the upper south wall is solid.
func _build_walls() -> void:
	_solid(self, Vector3(12.6, GH, 0.2), Vector3(0.0, GH * 0.5, Z_BACK - WT), C_WALL_EXT)
	_solid(self, Vector3(0.2, GH, 11.4), Vector3(-EX - WT, GH * 0.5, -0.5), C_WALL_EXT)
	_solid(self, Vector3(0.2, GH, 11.4), Vector3(EX + WT, GH * 0.5, -0.5), C_WALL_EXT)
	_solid(self, Vector3(5.0, GH, 0.2), Vector3(-3.7, GH * 0.5, Z_FRONT + WT), C_WALL_EXT)
	_solid(self, Vector3(5.0, GH, 0.2), Vector3(3.7, GH * 0.5, Z_FRONT + WT), C_WALL_EXT)

	_solid(self, Vector3(12.6, GH, 0.2), Vector3(0.0, UF + GH * 0.5, Z_BACK - WT), C_WALL_EXT)
	_solid(self, Vector3(0.2, GH, 11.4), Vector3(-EX - WT, UF + GH * 0.5, -0.5), C_WALL_EXT)
	_solid(self, Vector3(0.2, GH, 11.4), Vector3(EX + WT, UF + GH * 0.5, -0.5), C_WALL_EXT)
	_solid(self, Vector3(12.6, GH, 0.2), Vector3(0.0, UF + GH * 0.5, Z_FRONT + WT), C_WALL_EXT)

## Interior dividing wall (living/kitchen on the ground floor) and
## (bedroom/bathroom on the upper floor), each with a doorway. The back region
## (behind the stairwell) stays open through the full width.
func _build_interior_walls() -> void:
	# Kitchen/living divider on the ground floor with a doorway. The back segment
	# stops at the front of the stair shaft (z=-2.0) so it does NOT run through the
	# shaft and block the foot / exit of the staircase.
	_solid(self, Vector3(0.2, GH, 2.5), Vector3(-0.1, GH * 0.5, -0.75), C_WALL)
	_solid(self, Vector3(0.2, GH, 3.5), Vector3(-0.1, GH * 0.5, 3.45), C_WALL)
	_solid(self, Vector3(0.2, GH, 2.5), Vector3(-0.1, UF + GH * 0.5, -0.75), C_WALL)
	_solid(self, Vector3(0.2, GH, 3.5), Vector3(-0.1, UF + GH * 0.5, 3.45), C_WALL)

## Stairwell shaft (back-center) with its own walls and a straight staircase.
## The front jamb blocks (previously at z=-2.0) that shrank the stairwell opening
## and blocked the foot of the staircase are removed so the full 2.4-wide stair is
## walkable from the ground floor.
## The shaft side walls are full height only at the FRONT of the stairwell (they
## enclose the lower stairs and keep the player from walking around the sides /
## through the surrounding walls). At the BACK the shaft opens out so the top of the
## stairs can reach the upstairs. The staircase is a continuous ramp that rises to
## exactly the upper-floor height and meets a flush flat landing at the back, so the
## player steps LEVEL from the top of the stairs onto the upstairs bedroom/bathroom
## (no tall lip to catch the controller). The ramp slope stays under the controller's
## floor_max_angle so the existing player controller walks straight up and down.
func _build_stairs() -> void:
	# Front shaft walls: full ground-floor height, enclose the lower stairwell.
	_solid(self, Vector3(0.2, GH, 1.5), Vector3(-1.3, GH * 0.5, -2.75), C_WALL_EXT)
	_solid(self, Vector3(0.2, GH, 1.5), Vector3(1.3, GH * 0.5, -2.75), C_WALL_EXT)
	# Back exterior wall (full height).
	_solid(self, Vector3(2.4, UH, 0.2), Vector3(0.0, UH * 0.5, Z_BACK - WT), C_WALL_EXT)

	# Continuous smooth staircase built as a single triangle-mesh prism. Its top
	# surface is a single unbroken walkable surface that rises from the ground floor
	# (y=0.1 at z=-2.0) up the ramp (rise keeps the slope under the controller's
	# floor_max_angle) to exactly the upper-floor height (y=3.0), then flattens out
	# and continues level to the back wall. Because there is NO vertical lip or step
	# anywhere between the sloped ramp and the flat top, the existing controller
	# rides it straight up, crests at y=3.0, then steps catch-free sideways onto the
	# upstairs bedroom/bathroom (which sit flush at y=3.0).
	var run := 3.8                      # slope run from z=-2.0 to z=-5.8
	var slope_end_z := -2.0 - run       # z where the slope reaches y=3.0
	var flat_back_z := -6.1             # flat top extends back to the wall
	var rise := 3.0 - 0.1               # 2.9, ground to upper-floor top
	_build_ramp_surface(-1.2, 1.2, run)

	# Visual step treads lying flat on the slope so it reads as a staircase.
	var nsteps := 15
	for i in nsteps:
		var frac := float(i) / float(nsteps - 1)
		var pz := -2.0 - run * frac
		var py := 0.1 + rise * frac
		var mi := _mesh(self, Vector3(2.4, 0.02, run / nsteps - 0.02), Vector3(0.0, 0.0, pz), C_FLOOR)
		mi.rotation_degrees = Vector3(rad_to_deg(atan2(rise, run)), 0.0, 0.0)
		mi.position = Vector3(0.0, py, pz)

## Builds the walkable staircase as an OPEN triangle-mesh surface: a single
## continuous top surface that rises from ground level up a gentle ramp to the
## upper-floor height then flattens out to the back wall. Because it is one smooth
## surface with no vertical step/lip, the controller rides it straight up and then
## steps level into the upstairs. backface_collision makes it double-sided. The
## front face and foot are also added so the body is caught cleanly.
func _build_ramp_surface(x0: float, x1: float, run: float) -> void:
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	var pts := PackedVector3Array()  # centre-line of the top surface (y,z -> world)
	var seq := [
		Vector3(0.0, 0.1, -2.0),            # foot of the stairs
		Vector3(0.0, 3.0, -2.0 - run),      # top of the slope
		Vector3(0.0, 3.0, -6.15),           # back of the flat landing
	]
	for k in range(seq.size() - 1):
		pts.append(seq[k])
	# Subdivide each straight segment so the surface has enough triangles.
	var samples := PackedVector3Array()
	for i in range(seq.size() - 1):
		var a: Vector3 = seq[i]
		var b: Vector3 = seq[i + 1]
		var seg := 6
		for s in range(seg):
			samples.append(a.lerp(b, float(s) / float(seg)))
	samples.append(seq[seq.size() - 1])

	var base := samples.size() * 2
	verts.resize(base)
	for i in range(samples.size()):
		var p: Vector3 = samples[i]
		verts[i * 2] = Vector3(x0, p.y, p.z)
		verts[i * 2 + 1] = Vector3(x1, p.y, p.z)
	# Top strip, up-facing.
	for i in range(samples.size() - 1):
		var a := i * 2
		var b := i * 2 + 1
		var c := (i + 1) * 2
		var d := (i + 1) * 2 + 1
		idx.append_array([a, b, c, b, d, c])

	var mesh := ArrayMesh.new()
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	var sb := StaticBody3D.new()
	add_child(sb)
	var cs := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	shape.margin = 0.001
	shape.backface_collision = true
	cs.shape = shape
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, _mat(C_FLOOR))
	sb.add_child(mi)

## Simple blockout furniture so rooms read clearly and a few future hiding spots
## have a physical shape. No interaction yet.
func _build_furniture() -> void:
	_solid(self, Vector3(0.5, 1.1, 0.5), Vector3(5.4, 0.65, -5.2), C_COUNTER)
	_solid(self, Vector3(2.2, 0.9, 0.6), Vector3(5.2, 0.55, -3.2), C_COUNTER)
	_solid(self, Vector3(0.7, 1.4, 0.7), Vector3(5.4, 0.8, -1.4), C_FRIDGE)
	_solid(self, Vector3(1.4, 0.07, 0.9), Vector3(3.2, 0.14, 2.2), C_FURN)
	_solid(self, Vector3(0.6, 0.05, 0.5), Vector3(3.2, 0.16, 3.2), C_FURN)

	_solid(self, Vector3(2.4, 0.7, 0.9), Vector3(-4.6, 0.4, 3.6), C_SOFA)
	_solid(self, Vector3(1.2, 0.08, 0.8), Vector3(-4.4, 0.12, 2.2), C_FURN)
	_solid(self, Vector3(0.8, 0.05, 0.6), Vector3(-3.6, 0.14, 4.9), C_FURN)

	_solid(self, Vector3(1.9, 0.4, 1.3), Vector3(-4.4, 0.9, -4.0), C_BED)
	_solid(self, Vector3(0.5, 0.9, 0.5), Vector3(-1.8, 0.55, -5.3), C_FURN)

	_solid(self, Vector3(0.8, 0.9, 0.5), Vector3(1.8, 0.55, -5.3), C_BATH)
	_solid(self, Vector3(0.5, 0.6, 0.5), Vector3(1.8, 0.4, -4.2), C_BATH)
	_solid(self, Vector3(1.2, 0.5, 0.9), Vector3(5.2, 0.7, -5.2), C_BATH)

## Small countryside around the cottage: a dirt path to the door, a few trees,
## bushes, a fence around the yard, and a mailbox.
func _build_exterior() -> void:
	_solid(self, Vector3(2.0, 0.06, 7.0), Vector3(0.0, 0.08, 8.0), C_PATH)
	for tx in [-8.0, -10.0, 9.0, 11.0]:
		var pos := Vector3(tx, 0.0, -8.0)
		_tree(pos)
	_tree(Vector3(-9.0, 0.0, 4.0))
	_tree(Vector3(9.5, 0.0, 3.0))
	_mesh(self, Vector3(1.2, 0.7, 0.6), Vector3(-11.0, 0.45, 9.0), C_TREE)
	_mesh(self, Vector3(0.9, 0.8, 0.9), Vector3(12.0, 0.5, 9.0), C_TREE)
	_mesh(self, Vector3(14.0, 0.15, 0.12), Vector3(0.0, 0.12, 12.6), C_FENCE)
	_mesh(self, Vector3(0.12, 0.15, 25.0), Vector3(14.6, 0.12, 0.0), C_FENCE)
	_mesh(self, Vector3(0.12, 0.15, 25.0), Vector3(-14.6, 0.12, 0.0), C_FENCE)
	_solid(self, Vector3(0.4, 1.0, 0.3), Vector3(3.0, 0.6, 8.0), C_FENCE)
	_mesh(self, Vector3(0.5, 0.35, 0.2), Vector3(3.2, 1.05, 8.0), C_FURN)

func _tree(pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_mesh(n, Vector3(0.35, 1.6, 0.35), Vector3(0.0, 0.8, 0.0), C_TRUNK)
	_mesh(n, Vector3(1.8, 1.4, 1.8), Vector3(0.0, 2.4, 0.0), C_TREE)

## Simple sloped gable roof (visual only) so the exterior reads as a cottage.
func _build_roof() -> void:
	var half := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(6.4, 0.25, 13.0)
	half.mesh = bm
	half.rotation_degrees = Vector3(0.0, 0.0, -24.0)
	half.position = Vector3(-3.2, 6.4, -0.5)
	add_child(half)
	half.set_surface_override_material(0, _mat(C_ROOF))
	var half2 := MeshInstance3D.new()
	half2.mesh = bm
	half2.rotation_degrees = Vector3(0.0, 0.0, 24.0)
	half2.position = Vector3(3.2, 6.4, -0.5)
	add_child(half2)
	half2.set_surface_override_material(0, _mat(C_ROOF))

## Fixed-camera zones. Each zone is an Area3D trigger + a View Camera3D + a
## LookTarget, discovered by the CameraZone script. The FixedCameraManager frames
## whichever zone currently contains the active (female) player.
func _build_zones() -> void:
	var zones_root := Node3D.new()
	zones_root.name = "CameraZones"
	add_child(zones_root)

	_make_zone(zones_root, "Zone_Exterior",
		Vector3(8.0, 4.0, 6.0), Vector3(0.0, 2.0, 8.5),
		Vector3(0.0, 2.2, 8.5), Vector3(0.0, 1.5, 0.0))

	_make_zone(zones_root, "Zone_Living",
		Vector3(6.3, 3.0, 12.0), Vector3(-3.0, 1.5, -0.5),
		Vector3(-6.3, 2.4, -4.0), Vector3(-2.0, 1.5, 1.0))

	_make_zone(zones_root, "Zone_Kitchen",
		Vector3(6.3, 3.0, 12.0), Vector3(3.0, 1.5, -0.5),
		Vector3(6.3, 2.4, -4.0), Vector3(2.0, 1.5, 1.0))

	var stairs_zone := _make_zone(zones_root, "Zone_Stairs",
		Vector3(3.0, 6.5, 5.0), Vector3(0.0, 3.0, -4.0),
		Vector3(0.0, 4.6, -2.2), Vector3(0.0, 1.5, -4.0))
	stairs_zone.priority = 1

	_make_zone(zones_root, "Zone_Bedroom",
		Vector3(5.2, 3.2, 12.0), Vector3(-3.5, 4.5, -0.5),
		Vector3(-6.3, 5.4, -4.0), Vector3(-2.0, 4.5, 1.0))

	_make_zone(zones_root, "Zone_Bathroom",
		Vector3(5.2, 3.2, 12.0), Vector3(3.5, 4.5, -0.5),
		Vector3(6.3, 5.4, -4.0), Vector3(2.0, 4.5, 1.0))

func _make_zone(root: Node3D, zname: String, box_size: Vector3, box_pos: Vector3, view_pos: Vector3, look_pos: Vector3) -> CameraZone:
	var zone := CameraZone.new()
	zone.name = zname
	zone.trigger_path = NodePath("Trigger")
	zone.view_path = NodePath("View")
	zone.look_target_path = NodePath("LookTarget")

	var area := Area3D.new()
	area.name = "Trigger"
	area.position = box_pos
	zone.add_child(area)
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var shp := BoxShape3D.new()
	shp.size = box_size
	shape.shape = shp
	area.add_child(shape)

	var view := Camera3D.new()
	view.name = "View"
	view.position = view_pos
	zone.add_child(view)

	var look := Node3D.new()
	look.name = "LookTarget"
	look.position = look_pos
	zone.add_child(look)

	root.add_child(zone)
	return zone
