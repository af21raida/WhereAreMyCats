class_name CottageBuilder
extends Node3D
## Phase 3+5 — builds the cottage blockout plus Phase 5 low-poly environment
## enrichment (detailed furniture props and richer exterior greenery) from an
## explicit layout table. Runs once in _ready(); everything is plain primitive
## boxes and simple flat materials suitable for a PS1-style look. No external
## asset files are used — all geometry is generated in code with flat materials
## and nearest-neighbor texture filtering. The Phase 5 props are visual-only
## (no collision) so they never disturb movement, collisions or the stairs.

const WT := 0.2
const GH := 3.0
const UF := 3.0
const UH := 6.0
const EX := 6.0
const Z_BACK := -6.0
const Z_FRONT := 5.0

const C_GRASS := Color(0.42, 0.58, 0.34)
const C_DIRT := Color(0.56, 0.45, 0.35)
const C_WALL := Color(0.86, 0.8, 0.7)
const C_WALL_EXT := Color(0.64, 0.54, 0.42)
const C_FLOOR := Color(0.56, 0.42, 0.28)
const C_ROOF := Color(0.5, 0.33, 0.28)
const C_FURN := Color(0.5, 0.38, 0.26)
const C_SOFA := Color(0.56, 0.42, 0.35)
const C_COUNTER := Color(0.8, 0.73, 0.6)
const C_FRIDGE := Color(0.68, 0.68, 0.7)
const C_BED := Color(0.7, 0.62, 0.56)
const C_BATH := Color(0.82, 0.85, 0.87)
const C_TREE := Color(0.35, 0.55, 0.28)
const C_TRUNK := Color(0.48, 0.36, 0.24)
const C_FENCE := Color(0.62, 0.52, 0.38)
const C_PATH := Color(0.62, 0.52, 0.39)
# Phase 5 prop palette (accents, kept muted/warm for the PS1 look).
const C_SINK := Color(0.75, 0.82, 0.84)
const C_RUG_L := Color(0.62, 0.34, 0.28)
const C_RUG_B := Color(0.36, 0.42, 0.55)
const C_BLANKET := Color(0.5, 0.28, 0.24)
const C_PILLOW := Color(0.9, 0.86, 0.78)
const C_WOOD_D := Color(0.42, 0.3, 0.2)
const C_PLANT := Color(0.3, 0.5, 0.24)
const C_POT := Color(0.55, 0.34, 0.22)
const C_BOOK := Color(0.55, 0.3, 0.24)
const C_BOOK2 := Color(0.45, 0.5, 0.3)
const C_BOOK3 := Color(0.3, 0.42, 0.5)
const C_FLOWER_R := Color(0.68, 0.3, 0.26)
const C_FLOWER_Y := Color(0.78, 0.66, 0.3)
const C_FLOWER_W := Color(0.9, 0.88, 0.8)
const C_METAL := Color(0.6, 0.62, 0.64)
const C_STONE := Color(0.62, 0.6, 0.55)
const C_FIREWOOD := Color(0.52, 0.36, 0.22)

var _cache: Dictionary = {}

func _ready() -> void:
	_build_base()
	_build_walls()
	_build_entrance()
	_build_interior_walls()
	_build_stairs()
	_build_furniture()
	_build_props()
	_build_exterior()
	_build_roof()
	_build_zones()

func _mat(c: Color) -> StandardMaterial3D:
	if _cache.has(c):
		return _cache[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
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
	# The exterior ground is kept clearly BELOW the interior floor (top at y=0.1)
	# so its top surface is never coplanar with the floor slab — that overlap caused
	# z-fighting (the whole cottage floor flickered once the low-res PS1 post-process
	# exposed it).
	_solid(self, Vector3(30.0, 0.4, 26.0), Vector3(0.0, -0.18, 0.0), C_GRASS)
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

## The single entrance: a proper rectangular doorway opening in the front-wall
## gap (x -1.2..1.2). Only this one walkable exterior opening exists — the other
## walls are solid. A wooden door frame (two jambs + lintel) and an outer doorstep
## frame the opening but do NOT occupy it, so the passage stays genuinely open
## (a physical, swing-able door leaf is left to Phase 6).
func _build_entrance() -> void:
	# Frame: two jambs and a lintel around the opening.
	_mesh(self, Vector3(0.12, GH, 0.12), Vector3(-1.15, GH * 0.5, 5.22), C_WOOD_D)
	_mesh(self, Vector3(0.12, GH, 0.12), Vector3(1.15, GH * 0.5, 5.22), C_WOOD_D)
	_mesh(self, Vector3(2.4, 0.12, 0.12), Vector3(0.0, GH - 0.06, 5.22), C_WOOD_D)

## Interior dividing wall (living/kitchen on the ground floor) and
## (bedroom/bathroom on the upper floor), each with a doorway. The back segments
## (which previously ran at x=-0.1 through the CENTER of the open stairwell at its
## foot/top, z -2.0..0.5) are REMOVED so the staircase stays completely visually
## open. Only the front segment of each floor remains, dividing the rooms in the
## main area where a wall should logically exist. The ground-floor front segment
## stops short of the front wall (z 1.6..4.4) so it does NOT straddle the centered
## front-door opening: entering the door lands in a clear foyer and the player can
## walk around the divider into either room instead of walking straight into it.
func _build_interior_walls() -> void:
	# Ground floor: kitchen/living divider in the front area (z 1.6..4.4). Ends
	# before the front wall so the doorway/foyer stays a genuine open passage.
	_solid(self, Vector3(0.2, GH, 2.8), Vector3(-0.1, GH * 0.5, 3.0), C_WALL)
	# Upper floor: bedroom/bathroom divider in the front area (z 1.7..5.2).
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

	_solid(self, Vector3(1.9, 0.4, 1.3), Vector3(-4.4, 3.9, -4.0), C_BED)
	_solid(self, Vector3(0.5, 0.9, 0.5), Vector3(-5.35, 3.55, -4.0), C_FURN)

	_solid(self, Vector3(0.8, 0.9, 0.5), Vector3(1.8, 3.55, -5.3), C_BATH)
	_solid(self, Vector3(0.5, 0.6, 0.5), Vector3(1.8, 3.4, -4.2), C_BATH)
	_solid(self, Vector3(1.2, 0.5, 0.9), Vector3(5.2, 3.7, -5.2), C_BATH)

## Phase 5 — visual-only PS1 detail props (no collision, so movement, collisions
## and the stairs are never disturbed). Adds furniture detail to the kitchen,
## living room, bedroom and bathroom, plus a few interior rugs/plants.
func _build_props() -> void:
	# Kitchen: sink on the counter, an upper cabinet row, a dining table + 2 chairs,
	# and a wall shelf.
	_mesh(self, Vector3(0.34, 0.05, 0.4), Vector3(5.0, 1.18, -4.5), C_SINK)
	_mesh(self, Vector3(0.4, 0.55, 2.8), Vector3(5.85, 2.28, -3.2), C_FURN)
	_mesh(self, Vector3(1.5, 0.08, 1.0), Vector3(3.0, 0.84, 4.6), C_WOOD_D)
	_mesh(self, Vector3(0.1, 0.7, 0.1), Vector3(2.25, 0.42, 4.3), C_WOOD_D)
	_mesh(self, Vector3(0.1, 0.7, 0.1), Vector3(3.75, 0.42, 4.3), C_WOOD_D)
	_mesh(self, Vector3(0.1, 0.7, 0.1), Vector3(2.25, 0.42, 4.9), C_WOOD_D)
	_mesh(self, Vector3(0.1, 0.7, 0.1), Vector3(3.75, 0.42, 4.9), C_WOOD_D)
	_mesh(self, Vector3(0.45, 0.06, 0.45), Vector3(2.1, 0.5, 4.3), C_FURN)
	_mesh(self, Vector3(0.45, 0.06, 0.45), Vector3(3.9, 0.5, 4.3), C_FURN)
	_mesh(self, Vector3(0.45, 0.5, 0.45), Vector3(2.1, 0.27, 4.3), C_WOOD_D)
	_mesh(self, Vector3(0.45, 0.5, 0.45), Vector3(3.9, 0.27, 4.3), C_WOOD_D)
	_mesh(self, Vector3(0.04, 0.35, 0.35), Vector3(3.0, 1.3, 4.6), C_FURN)
	_mesh(self, Vector3(0.5, 0.4, 0.4), Vector3(3.0, 1.55, 4.6), C_POT)
	_mesh(self, Vector3(0.4, 0.4, 0.4), Vector3(3.0, 1.85, 4.6), C_PLANT)

	# Living room: coffee table, a bookshelf with book rows, a plant, a fireplace
	# with mantle, and a rug on the floor.
	_mesh(self, Vector3(0.9, 0.06, 0.6), Vector3(-4.6, 0.55, 4.6), C_WOOD_D)
	_mesh(self, Vector3(0.5, 0.04, 0.35), Vector3(-2.4, 2.26, 3.0), C_FURN)
	_mesh(self, Vector3(0.06, 1.9, 0.3), Vector3(-5.9, 2.15, 3.0), C_WOOD_D)
	_mesh(self, Vector3(0.6, 0.06, 0.3), Vector3(-5.9, 1.25, 3.0), C_WOOD_D)
	_mesh(self, Vector3(0.6, 0.06, 0.3), Vector3(-5.9, 1.6, 3.0), C_WOOD_D)
	_mesh(self, Vector3(0.6, 0.06, 0.3), Vector3(-5.9, 1.95, 3.0), C_WOOD_D)
	_mesh(self, Vector3(0.5, 0.05, 0.22), Vector3(-5.9, 1.33, 3.0), C_BOOK)
	_mesh(self, Vector3(0.5, 0.05, 0.22), Vector3(-5.9, 1.68, 3.0), C_BOOK2)
	_mesh(self, Vector3(0.5, 0.05, 0.22), Vector3(-5.9, 2.03, 3.0), C_BOOK3)
	_mesh(self, Vector3(0.5, 0.65, 0.5), Vector3(-4.0, 0.55, 4.9), C_STONE)
	_mesh(self, Vector3(2.0, 0.06, 0.4), Vector3(-4.0, 1.15, 4.9), C_WOOD_D)
	_mesh(self, Vector3(0.7, 0.03, 0.9), Vector3(-4.6, 0.115, 2.6), C_RUG_L)

	# Bedroom: headboard + blanket / pillow detail on the bed, a wardrobe with
	# doors, a nightstand lamp and a rug.
	_mesh(self, Vector3(1.9, 0.6, 0.15), Vector3(-4.4, 4.5, -3.15), C_WOOD_D)
	_mesh(self, Vector3(1.7, 0.12, 1.1), Vector3(-4.4, 4.36, -4.0), C_BLANKET)
	_mesh(self, Vector3(0.5, 0.1, 0.35), Vector3(-3.5, 4.5, -4.55), C_PILLOW)
	_mesh(self, Vector3(0.8, 1.9, 0.4), Vector3(-5.75, 5.05, -2.0), C_WOOD_D)
	_mesh(self, Vector3(0.04, 0.6, 0.32), Vector3(-5.75, 4.25, -2.0), C_FURN)
	_mesh(self, Vector3(0.9, 0.04, 0.9), Vector3(-2.6, 3.015, -5.9), C_RUG_B)
	_mesh(self, Vector3(0.06, 0.3, 0.06), Vector3(-5.35, 3.75, -4.0), C_METAL)
	_mesh(self, Vector3(0.16, 0.04, 0.16), Vector3(-5.35, 3.9, -4.0), C_PILLOW)

	# Bathroom: a wall mirror and a couple of towel rails.
	_mesh(self, Vector3(0.04, 0.5, 0.35), Vector3(1.8, 3.9, -5.55), C_SINK)
	_mesh(self, Vector3(0.7, 0.05, 0.05), Vector3(3.0, 3.6, -5.0), C_METAL)
	_mesh(self, Vector3(0.2, 0.28, 0.05), Vector3(2.85, 3.42, -5.0), C_BLANKET)

	# A few interior floor pockets in the open living/kitchen for plant life.
	_mesh(self, Vector3(0.5, 0.5, 0.5), Vector3(5.6, 0.28, 2.4), C_POT)
	_mesh(self, Vector3(0.4, 0.4, 0.4), Vector3(5.6, 0.55, 2.4), C_PLANT)
	_mesh(self, Vector3(0.5, 0.5, 0.5), Vector3(-5.4, 0.28, 1.0), C_POT)
	_mesh(self, Vector3(0.4, 0.4, 0.4), Vector3(-5.4, 0.55, 1.0), C_PLANT)

## Small countryside around the cottage: a dirt path to the door, a few trees,
## bushes, a fence around the yard, and a mailbox.
func _build_exterior() -> void:
	_solid(self, Vector3(2.0, 0.06, 7.0), Vector3(0.0, 0.05, 8.0), C_PATH)
	for tx in [-8.0, -10.0, 9.0, 11.0]:
		var pos := Vector3(tx, 0.0, -8.0)
		_tree(pos)
	_tree(Vector3(-9.0, 0.0, 4.0))
	_tree(Vector3(9.5, 0.0, 3.0))
	_tree_variant(Vector3(-7.0, 0.0, -9.0), 0.7)
	_tree_variant(Vector3(12.0, 0.0, -4.0), 1.25)
	_tree_variant(Vector3(-13.0, 0.0, 6.0), 0.85)
	_tree_variant(Vector3(13.5, 0.0, 5.0), 1.1)
	_mesh(self, Vector3(1.2, 0.7, 0.6), Vector3(-11.0, 0.45, 9.0), C_TREE)
	_mesh(self, Vector3(0.9, 0.8, 0.9), Vector3(12.0, 0.5, 9.0), C_TREE)
	_mesh(self, Vector3(14.0, 0.15, 0.12), Vector3(0.0, 0.12, 12.6), C_FENCE)
	_mesh(self, Vector3(0.12, 0.15, 25.0), Vector3(14.6, 0.12, 0.0), C_FENCE)
	_mesh(self, Vector3(0.12, 0.15, 25.0), Vector3(-14.6, 0.12, 0.0), C_FENCE)
	_solid(self, Vector3(0.4, 1.0, 0.3), Vector3(3.0, 0.6, 8.0), C_FENCE)
	_mesh(self, Vector3(0.5, 0.35, 0.2), Vector3(3.2, 1.05, 8.0), C_FURN)

	# Garden greenery and yard props (visual only).
	_shrub(Vector3(-4.0, 0.0, 8.2), 0.8)
	_shrub(Vector3(4.5, 0.0, 7.2), 1.0)
	_shrub(Vector3(-7.0, 0.0, 7.0), 0.7)
	_shrub(Vector3(8.0, 0.0, 8.5), 0.9)
	_shrub(Vector3(-8.5, 0.0, -6.5), 0.9)
	_shrub(Vector3(9.0, 0.0, -7.0), 1.0)
	_flowerbed(Vector3(-2.5, 0.0, 7.6), 0.5)
	_flowerbed(Vector3(5.5, 0.0, 7.8), 0.6)
	_flowerbed(Vector3(-5.5, 0.0, -3.0), 0.5)
	_flowerbed(Vector3(6.5, 0.0, -3.0), 0.5)
	# Firewood stack beside the cottage.
	for i in 3:
		_mesh(self, Vector3(0.6, 0.24, 0.24), Vector3(6.6, 0.12 + i * 0.24, 6.8), C_FIREWOOD)
		_mesh(self, Vector3(0.24, 0.24, 0.24), Vector3(6.2, 0.12 + i * 0.24, 6.8), C_FIREWOOD)
	# A small stone well by the path.
	_mesh(self, Vector3(0.6, 0.5, 0.6), Vector3(-6.0, 0.4, 5.6), C_STONE)
	_mesh(self, Vector3(0.09, 0.5, 0.6), Vector3(-6.8, 0.5, 5.6), C_WOOD_D)
	_mesh(self, Vector3(0.09, 0.5, 0.6), Vector3(-5.2, 0.5, 5.6), C_WOOD_D)
	# Inner doormat (rug) just inside the front door, resting on the floor.
	_mesh(self, Vector3(0.8, 0.04, 0.5), Vector3(0.0, 0.12, 4.85), C_RUG_B)
	# A short stone doorstep just outside the door, resting on the grass.
	_mesh(self, Vector3(1.3, 0.06, 0.5), Vector3(0.0, 0.05, 5.5), C_STONE)

func _tree(pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_mesh(n, Vector3(0.35, 1.6, 0.35), Vector3(0.0, 0.8, 0.0), C_TRUNK)
	_mesh(n, Vector3(1.8, 1.4, 1.8), Vector3(0.0, 2.4, 0.0), C_TREE)

func _tree_variant(pos: Vector3, s: float) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_mesh(n, Vector3(0.4, 2.0, 0.4) * s, Vector3(0.0, 1.0 * s, 0.0), C_TRUNK)
	_mesh(n, Vector3(2.0, 1.2, 2.0) * s, Vector3(0.0, 2.7 * s, 0.0), C_TREE)
	_mesh(n, Vector3(1.2, 1.0, 1.2) * s, Vector3(0.0, 1.9 * s, 0.0), C_TREE)

func _shrub(pos: Vector3, s: float) -> void:
	_mesh(self, Vector3(s, s * 0.7, s), pos + Vector3(0.0, s * 0.35, 0.0), C_TREE)
	_mesh(self, Vector3(s * 0.6, s * 0.5, s * 0.6), pos + Vector3(s * 0.25, s * 0.5, 0.0), C_PLANT)

func _flowerbed(pos: Vector3, s: float) -> void:
	for k in 4:
		var off := Vector3(((k % 2) * 2 - 1) * s * 0.25, 0.0, ((k / 2) * 2 - 1) * s * 0.25)
		_mesh(self, Vector3(0.03, 0.18, 0.03), pos + off + Vector3(0.0, 0.1, 0.0), C_PLANT)
		var c := C_FLOWER_R
		if k == 1:
			c = C_FLOWER_Y
		elif k == 2:
			c = C_FLOWER_W
		elif k == 3:
			c = C_FLOWER_Y
		_mesh(self, Vector3(0.12, 0.08, 0.12), pos + off + Vector3(0.0, 0.18, 0.0), c)

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
