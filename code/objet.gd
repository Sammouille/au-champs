extends RigidBody3D
class_name Objet

@export var nom:= "Produit"

@export var outline: MeshInstance3D
@export var meshes: Array[MeshInstance3D]
@onready var collision: CollisionShape3D = $CollisionShape3D

func desactivation_portee():
	$CollisionShape3D.disabled = true
	freeze = true

func reactivation_lache():
	$CollisionShape3D.disabled = false
	freeze = false

func simulation():
	freeze = true
	outline.hide()
	for mesh in meshes:
		mesh.mesh = mesh.mesh.duplicate()
		for surface in mesh.mesh.get_surface_count():
			mesh.mesh.surface_set_material(surface, mesh.mesh.surface_get_material(surface).duplicate())
			mesh.mesh.surface_get_material(surface).albedo_color.a = mesh.mesh.surface_get_material(surface).albedo_color.a * 0.2
	
	#outline.mesh = outline.mesh.duplicate()
	#
	#outline.mesh.surface_set_material(0, outline.mesh.surface_get_material(0).duplicate())
	#outline.mesh.surface_get_material(0).albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	#outline.show()
