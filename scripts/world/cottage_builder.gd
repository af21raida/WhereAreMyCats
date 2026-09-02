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

# Phase 7 cat palette (muted, in-palette: ginger/orange, tabby, tuxedo).
const C_GINGER_FUR := Color(0.78, 0.46, 0.2)
const C_GINGER_BELLY := Color(0.95, 0.85, 0.68)
const C_GINGER_EAR := Color(0.88, 0.6, 0.5)
const C_TABBY_FUR := Color(0.52, 0.44, 0.36)
const C_TABBY_BELLY := Color(0.78, 0.72, 0.62)
const C_TABBY_STRIPE := Color(0.35, 0.28, 0.23)
const C_TUX_FUR := Color(0.13, 0.13, 0.16)
const C_TUX_BELLY := Color(0.92, 0.92, 0.9)

var _cache: Dictionary = {}
var _kitchen_cab: InteractableCabinet
var _ginger: Cat
var _tabby: Cat
var _tuxedo: Cat

func _ready() -> void:
	_build_base()
	_build_walls()
	_build_entrance()
	_build_interior_walls()
	_build_stairs()
	_build_upstairs_hallway()
	_build_furniture()
	_build_props()
	_build_interactions()
	_build_cats()
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
	# Upstairs floor (top y 3.0). The whole SOUTH half is one large flat landing
	# wrapped around the open stairwell pit (west + centre + east slabs), and the
	# rooms sit up NORTH: facing +z (north) from the top of the stairs, the
	# BEDROOM (west, x<0) and the BATHROOM (east, x>0) are on the SAME side of
	# the landing and their doors stand side-by-side in the cross-wall at z=1.2.
	# The pit band (x -1.2..1.2, z -6.2..-2.0) stays open for the staircase.
	_solid(self, Vector3(5.0, 0.4, 7.4), Vector3(-3.7, 2.8, -2.5), C_FLOOR)   # landing (west of the pit)
	_solid(self, Vector3(5.0, 0.4, 7.4), Vector3(3.7, 2.8, -2.5), C_FLOOR)    # landing (east of the pit)
	_solid(self, Vector3(2.4, 0.4, 3.2), Vector3(0.0, 2.8, -0.4), C_FLOOR)    # landing (north of the pit)
	_solid(self, Vector3(6.2, 0.4, 4.0), Vector3(-3.1, 2.8, 3.2), C_FLOOR)    # bedroom (west/north)
	_solid(self, Vector3(6.2, 0.4, 4.0), Vector3(3.1, 2.8, 3.2), C_FLOOR)     # bathroom (east/north)

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
## (bedroom/bathroom on the upper floor), each with a doorway. The ground-floor
## back segments are REMOVED so the open stairwell stays completely visually
## open. On the upper floor the divider runs up the centre of the NORTH half
## (x=0, z 1.1..5.2): it splits the two upstairs rooms and sits just past the
## door-line of the single cross-wall at z=1.2, so the bedroom and bathroom doors
## stay side-by-side on the landing (bedroom west/left, bathroom east/right).
func _build_interior_walls() -> void:
	# Ground floor: kitchen/living divider in the front area (z 1.6..4.4). Ends
	# before the front wall so the doorway/foyer stays a genuine open passage.
	_solid(self, Vector3(0.2, GH, 2.8), Vector3(-0.1, GH * 0.5, 3.0), C_WALL)
	# Upper floor: bedroom/bathroom divider up the centre of the north half
	# (x 0, z 1.1..5.2, i.e. just north of the cross-wall door line).
	_solid(self, Vector3(0.2, GH, 4.1), Vector3(0.0, UF + GH * 0.5, 3.15), C_WALL)

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
	# The crest sits at z=-5.2 so the FLAT top of the stairs spans the doorway band
	# of both upstairs rooms (z=-6.15..-4.85); if the crest were any further north,
	# the doorway crossing would sit on the slope, leaving a vertical lip at the
	# threshold that blocked entering the bathroom on the diagonal.
	var run := 3.2                      # slope run from z=-2.0 to z=-5.2
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

## Upstairs (Phase 7 requirement, layout correction): one shared landing and two
## rooms stood side-by-side AHEAD of the player at the top of the stairs.
##
## The player climbs the stairs, crests at z=-5.2, walks around the open stairwell
## pit onto the flat landing, and faces straight north (toward +z) at the doors:
##   - a single cross-wall runs across the house at z=1.2 (y 3..6) split by the
##     two 1.3-wide door gaps (with a short nib between them);
##   - the BEDROOM (west/left) and BATHROOM (east/right) lie on the same side of
##     the landing (the north half), so both doors are visible side-by-side and
##     the rooms never open straight onto the staircase;
##   - coded, closed InteractableDoors hang in the gaps and swing NORTH (+z) INTO
##     their rooms, so from the landing the player sees two closed doors ahead and
##     must open one to pass.
## Low railings round the open stairwell pit (y 3..3.9) so the landing never turns
## into a cliff onto the descending staircase; the BACK corners stay open so the
## player steps sideways off the top of the stairs onto the landing.
func _build_upstairs_hallway() -> void:
	var wall_y := (UF + UH) * 0.5

	# Cross-wall at z=1.2 (y 3..6) in three pieces: west segment, centre nib,
	# east segment. The two door gaps land beside each other: x -1.85..-0.55
	# (bedroom door) and x 0.55..1.85 (bathroom door).
	_solid(self, Vector3(4.35, GH, 0.2), Vector3(-4.025, wall_y, 1.2), C_WALL)
	_solid(self, Vector3(1.1, GH, 0.2), Vector3(0.0, wall_y, 1.2), C_WALL)
	_solid(self, Vector3(4.35, GH, 0.2), Vector3(4.025, wall_y, 1.2), C_WALL)

	# Low railings around the stairwell pit at upper-floor level (y 3..3.9).
	_solid(self, Vector3(0.2, 0.9, 3.2), Vector3(-1.2, UF + 0.45, -3.6), C_WALL)
	_solid(self, Vector3(0.2, 0.9, 3.2), Vector3(1.2, UF + 0.45, -3.6), C_WALL)
	_solid(self, Vector3(2.4, 0.9, 0.2), Vector3(0.0, UF + 0.45, -2.0), C_WALL)

	# BEDROOM door: hinged on the EAST jamb of its gap, panel covers the gap and
	# swings NORTH (+z) INTO the bedroom. The 180° yaw maps local +x to world -x
	# (panel hangs back across the gap) while the positive 100° swing carries the
	# free edge north into the room.
	var bed := InteractableDoor.new()
	bed.name = "BedroomDoor"
	bed.setup_door(Vector3(-1.2, UF, 1.2), Vector3(-0.65, 0.0, 0.0))
	bed.rotation_degrees.y = 180.0
	bed.is_open = false
	bed.floor_level = 1
	bed.panel_color = C_WOOD_D
	add_child(bed)

	# BATHROOM door: the mirror image of the bedroom door on the other side of
	# the nib, hinged on the east jamb and swinging north into the bathroom.
	var bath := InteractableDoor.new()
	bath.name = "BathroomDoor"
	bath.setup_door(Vector3(1.2, UF, 1.2), Vector3(-0.65, 0.0, 0.0))
	bath.rotation_degrees.y = 180.0
	bath.is_open = false
	bath.floor_level = 1
	bath.panel_color = C_WOOD_D
	add_child(bath)

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

	# Bedroom (west/north half): bed + bedside table against the north wall.
	_solid(self, Vector3(1.9, 0.4, 1.3), Vector3(-3.3, 3.9, 4.35), C_BED)
	_solid(self, Vector3(0.5, 0.9, 0.5), Vector3(-2.1, 3.55, 4.35), C_FURN)

	# Bathroom (east/north half): sink on the north wall under the light switch,
	# toilet in the west-mid, and the bathtub hugging the EAST wall. The doorway
	# and the whole entry/turn-around area immediately inside it stay open so the
	# female, the male companion and every cat can step straight in.
	_solid(self, Vector3(1.2, 0.5, 0.9), Vector3(5.4, 3.7, 4.4), C_BATH)
	_solid(self, Vector3(0.5, 0.6, 0.5), Vector3(2.9, 3.4, 3.0), C_BATH)
	_solid(self, Vector3(0.8, 0.9, 0.5), Vector3(5.4, 3.55, 3.0), C_BATH)

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

	# Bedroom: headboard + blanket / pillow detail on the bed (head against the
	# north wall), a wardrobe on the west wall, a nightstand lamp and a rug.
	_mesh(self, Vector3(1.9, 0.6, 0.15), Vector3(-3.3, 4.5, 5.03), C_WOOD_D)
	_mesh(self, Vector3(1.7, 0.12, 1.1), Vector3(-3.3, 4.36, 4.35), C_BLANKET)
	_mesh(self, Vector3(0.5, 0.1, 0.35), Vector3(-3.3, 4.55, 4.9), C_PILLOW)
	_mesh(self, Vector3(0.8, 1.9, 0.4), Vector3(-6.02, 5.05, 3.5), C_WOOD_D)
	_mesh(self, Vector3(0.04, 0.6, 0.32), Vector3(-6.02, 4.25, 3.5), C_FURN)
	_mesh(self, Vector3(0.9, 0.04, 0.9), Vector3(-1.6, 3.015, 3.4), C_RUG_B)
	_mesh(self, Vector3(0.06, 0.3, 0.06), Vector3(-2.1, 4.18, 4.35), C_METAL)
	_mesh(self, Vector3(0.16, 0.04, 0.16), Vector3(-2.1, 4.32, 4.35), C_PILLOW)

	# Bathroom: a wall mirror above the sink and a couple of towel rails on the
	# north wall.
	_mesh(self, Vector3(0.04, 0.5, 0.35), Vector3(5.4, 4.3, 5.05), C_SINK)
	_mesh(self, Vector3(0.7, 0.05, 0.05), Vector3(4.2, 3.55, 5.05), C_METAL)
	_mesh(self, Vector3(0.2, 0.28, 0.05), Vector3(4.2, 3.4, 5.04), C_BLANKET)

	# A few interior floor pockets in the open living/kitchen for plant life.
	_mesh(self, Vector3(0.5, 0.5, 0.5), Vector3(5.6, 0.28, 2.4), C_POT)
	_mesh(self, Vector3(0.4, 0.4, 0.4), Vector3(5.6, 0.55, 2.4), C_PLANT)
	_mesh(self, Vector3(0.5, 0.5, 0.5), Vector3(-5.4, 0.28, 1.0), C_POT)
	_mesh(self, Vector3(0.4, 0.4, 0.4), Vector3(-5.4, 0.55, 1.0), C_PLANT)

## Phase 6 — interactive props. Adds Interactable nodes (door, cabinet, light
## switch, inspectables) that the InteractionManager detects near the female.
func _build_interactions() -> void:
	# Front door: a hinged panel at the entrance, default OPEN (passage clear).
	var door := InteractableDoor.new()
	door.setup_door(
		Vector3(0.0, GH * 0.5, Z_FRONT + WT),   # doorway center
		Vector3(-0.65, 0.0, 0.0)                # left hinge (swings inward)
	)
	door.panel_color = C_WOOD_D
	door.floor_level = 0   # ground floor (entrance)
	add_child(door)

	# Kitchen cabinet (Ginger's hiding spot, Phase 7): an opening cabinet on the
	# counter wall. The counter is at (5.4, 0.65, -5.2); place the cabinet on the
	# wall above the sink, facing +z.
	#
	# Per the Phase 7 direction, the cabinet shows NO interaction prompt: the
	# player opens it as an act of exploration and discovers Bread (Ginger)
	# inside. It still opens/closes normally on E.
	var cab := InteractableCabinet.new()
	cab.setup_cabinet(Vector3(5.0, GH - 0.85, -5.2), Vector3(-0.35, 0.0, 0.0))
	cab.panel_color = C_FURN
	cab.floor_level = 0   # ground floor (kitchen counter)
	cab.prompt = ""       # no hint text — silent exploration
	add_child(cab)
	_kitchen_cab = cab

	# Bathroom light switch on the NORTH wall of the bathroom, facing into the
	# room (south, -z). It toggles the `bathroom_light` Omni (added below), which
	# starts OFF (dark room). Mounted flush ON the wall's inner face (z=5.1),
	# near (5.4, UF+1.3, 5.12) so the PS1 plate is fully visible and not embedded
	# in the wall.
	var sw := InteractableSwitch.new()
	sw.setup_switch(Vector3(5.4, UF + 1.3, 5.12))
	sw.floor_level = 1   # upper floor (bathroom wall)
	add_child(sw)

	# The bathroom's light. Starts OFF so the room is dark (Phase 8 mechanic);
	# grouped so the switch toggles it. Grouped nodes are world-space discoverable.
	var b_light := OmniLight3D.new()
	b_light.name = "BathroomLight"
	b_light.position = Vector3(3.1, UF + 1.8, 3.2)
	b_light.omni_range = 6.0
	b_light.light_color = Color(1, 0.95, 0.8)
	b_light.light_energy = 1.4
	b_light.visible = false
	b_light.add_to_group("bathroom_light")
	add_child(b_light)

	# Inspectable props: a fireplace note, the dining table, the wardrobe, and the
	# bookshelf each give a short message when "interacted".
	_make_inspectable(Vector3(-4.0, 1.45, 4.9), "A stone fireplace, cold since last night. The mantle holds a dusty photo of two people and three cats.", 0)
	_make_inspectable(Vector3(3.0, 0.84, 4.6), "A small wooden dining table laid for two. Three saucers of milk wait by the wall — one for each cat?", 0)
	_make_inspectable(Vector3(-6.02, 5.05, 3.5), "A solid wardrobe. The doors are heavy and warp slightly when opened. You can't hear anything inside.", 1)
	_make_inspectable(Vector3(-5.9, 2.15, 3.0), "A shelf of old books:  cats  field guides, a hand-written cookbook, and one volume titled 'Where Are My Cats?'", 0)

func _make_inspectable(pos: Vector3, msg: String, floor_level := 0) -> void:
	var ins := Inspectable.new()
	ins.position = pos
	ins.message = msg
	ins.prompt = "Inspect"
	ins.floor_level = floor_level
	add_child(ins)

## Phase 7: the three hiding cats plus exploration-based discovery.
##
## No prompts reveal where the cats are. The only acknowledgement of a find is
## each cat's own discovery line:
##   Ginger -> "You found Bread!"
##   Tabby  -> "You found Inej!!!"
##   Tuxedo -> "You found Void!!"
## Ginger is revealed by opening the kitchen cabinet; Inej and Void are revealed
## automatically when the female explores near their hiding spots.
func _build_cats() -> void:
	# Ginger ("Bread"): inside the kitchen cabinet, just behind the closed panel.
	# No proximity reveal — only opening the cabinet reveals her.
	_ginger = Cat.new()
	_ginger.name = "Bread"
	_ginger.cat_id = &"ginger"
	_ginger.display_name = "Bread"
	_ginger.discovery_text = "You found Bread!"
	_ginger.hide_spot = "In the kitchen cabinet"
	_ginger.reveal_on_proximity = false
	_ginger.fur_color = C_GINGER_FUR
	_ginger.belly_color = C_GINGER_BELLY
	_ginger.ear_inner_color = C_GINGER_EAR
	_ginger.position = Vector3(5.0, GH - 0.85, -5.5)
	_ginger.scale = Vector3(0.8, 0.8, 0.8)
	add_child(_ginger)
	if _kitchen_cab != null:
		_kitchen_cab.interaction_performed.connect(_on_kitchen_cab_used)

	# Tabby ("Inej"): curled up under the bed in the upstairs bedroom. Found by
	# the female getting close (visual exploration under the bed).
	_tabby = Cat.new()
	_tabby.name = "Inej"
	_tabby.cat_id = &"tabby"
	_tabby.display_name = "Inej"
	_tabby.discovery_text = "You found Inej!!!"
	_tabby.hide_spot = "Under the bed"
	_tabby.reveal_on_proximity = true
	_tabby.proximity_radius = 1.2
	_tabby.fur_color = C_TABBY_FUR
	_tabby.belly_color = C_TABBY_BELLY
	_tabby.stripe_color = C_TABBY_STRIPE
	_tabby.position = Vector3(-3.3, UF + 0.05, 3.9)
	_tabby.rotation_degrees.y = 20.0
	add_child(_tabby)

	# Tuxedo ("Void"): on the dark bathroom floor, in the clear open mid area
	# (the bathtub hugs the east wall, the toilet sits nearer the door).
	# The bathroom light starts OFF, so the player must explore the dark room to
	# find her.
	_tuxedo = Cat.new()
	_tuxedo.name = "Void"
	_tuxedo.cat_id = &"tuxedo"
	_tuxedo.display_name = "Void"
	_tuxedo.discovery_text = "You found Void!!"
	_tuxedo.hide_spot = "In the dark bathroom"
	_tuxedo.reveal_on_proximity = true
	_tuxedo.proximity_radius = 1.0
	_tuxedo.fur_color = C_TUX_FUR
	_tuxedo.belly_color = C_TUX_BELLY
	_tuxedo.position = Vector3(1.8, UF + 0.05, 4.3)
	_tuxedo.rotation_degrees.y = -90.0
	add_child(_tuxedo)

func _on_kitchen_cab_used(_cab: InteractableCabinet) -> void:
	if _kitchen_cab != null and _kitchen_cab.is_open and _ginger != null:
		_ginger.reveal()

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
		Vector3(4.0, 6.5, 7.4), Vector3(0.0, 3.0, -2.5),
		Vector3(0.0, 4.6, -2.2), Vector3(0.0, 1.5, -4.0))
	stairs_zone.priority = 1

	_make_zone(zones_root, "Zone_Bedroom",
		Vector3(6.2, 3.2, 4.0), Vector3(-3.1, 4.5, 3.2),
		Vector3(-6.3, 5.4, 3.2), Vector3(-2.0, 4.5, 4.0))

	_make_zone(zones_root, "Zone_Bathroom",
		Vector3(6.2, 3.2, 4.0), Vector3(3.1, 4.5, 3.2),
		Vector3(6.3, 5.4, 3.2), Vector3(2.0, 4.5, 4.0))

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
