class_name CharacterModel
extends Node3D
## Procedural low-poly PS1-style humanoid built from primitives during Phase 1,
## shared by both protagonists. The Female and Male scenes configure different
## palettes/silhouettes through the exported properties. Later phases can swap
## this for baked models via an asset if desired.

@export var skin_color := Color(0.92, 0.76, 0.63)
@export var hair_color := Color(0.35, 0.26, 0.2)
@export var top_color := Color(0.62, 0.52, 0.46)
@export var bottom_color := Color(0.4, 0.35, 0.3)
@export var shoe_color := Color(0.28, 0.22, 0.18)
@export var is_female := true
@export var hair_length := 0.14

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()

	var body_half := 0.11
	var skin := _mat(skin_color)
	var hair := _mat(hair_color)
	var top := _mat(top_color)
	var bottom := _mat(bottom_color)
	var shoe := _mat(shoe_color)

	# Legs
	for side in [-1.0, 1.0]:
		var leg := _part(Vector3(body_half * 0.7, 0.35, body_half * 0.7), Vector3(0.09 * side, 0.35, 0), bottom)
		add_child(leg)
		var foot := _part(Vector3(body_half * 0.7, 0.07, body_half * 1.5), Vector3(0.09 * side, 0.07, 0.04), shoe)
		add_child(foot)

	# Torso
	var torso := _part(Vector3(body_half * 2.0, 0.5, body_half), Vector3(0, 0.95, 0), top)
	add_child(torso)

	# Arms
	for side in [-1.0, 1.0]:
		var arm := _part(Vector3(0.06, 0.46, 0.07), Vector3(body_half * 2.2 * side, 1.0, 0), top)
		add_child(arm)
		var hand := _part(Vector3(0.06, 0.06, 0.06), Vector3(body_half * 2.2 * side, 0.71, 0), skin)
		add_child(hand)

	# Head
	var head := _part(Vector3(0.2, 0.22, 0.2), Vector3(0, 1.4, 0), skin)
	add_child(head)

	# Hair
	var hair_height := 0.06 + hair_length
	var hair_part := _part(Vector3(0.22, hair_height, 0.22), Vector3(0, 1.52 + hair_height * 0.5, 0), hair)
	add_child(hair_part)

	# Simple accent accessory tied to each character for quick identification.
	_add_accent()

func _add_accent() -> void:
	# Female: small flower-like accent on the head hair. Male: a contrasting
	# button/scarf dot. Cheap but gives an immediate visual tell.
	if is_female:
		var flower := _part(Vector3(0.05, 0.03, 0.05), Vector3(0.08, 1.7, 0.1), _mat(Color(0.9, 0.7, 0.55)))
		add_child(flower)
	else:
		var dot := _part(Vector3(0.08, 0.03, 0.03), Vector3(0.0, 1.02, 0.14), _mat(Color(0.3, 0.45, 0.5)))
		add_child(dot)

func _part(aabb: Vector3, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = aabb
	mesh.material = material
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	return mi

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m
