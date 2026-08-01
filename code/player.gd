extends CharacterBody3D


@export var vitesse:= 40.0
@export var force_grav:= 60.0

@export var pic_sprint:= 80.0
@export var prog_sprint:= 0.8
var index_sprint:= 0.0

@export var vitesse_crouched:= 20.0

@export var puissance_saut:= 15.0

@export var puissance_frottements:= 5.0

@export var sensi_regard:= 0.1

@export var emplacements_objets: Array[Marker3D]

var objets_portes: Array[Objet]

var velocite:= Vector3.ZERO
var acceleration:= Vector3.ZERO

var rotacite:= Vector2.ZERO

var in_air:= false

var crouched:= false

var objet_vise: Objet

var simu_pose: Objet

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func appliquer_force(force: Vector3):
	acceleration += force

func appliquer_impulse(impulse: Vector3):
	velocity += impulse

func appliquer_frottements(delta: float):
	appliquer_force((-velocite -acceleration*delta) * puissance_frottements)

func appliquer_acceleration(delta: float):
	velocity += acceleration * delta
	acceleration = Vector3.ZERO
	velocite = velocity
	move_and_slide()

func get_move_input():
	var move_axis:= Vector2(Input.get_axis("droite", "gauche"), Input.get_axis("arriere","avant"))
	return move_axis.normalized()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotacite = event.relative
	if Input.is_action_just_pressed("crouch"):
		%Camera3D.position.y = 0.05
		crouched = true
	elif Input.is_action_just_released("crouch"):
		%Camera3D.position.y = 0.5
		crouched = false
	if Input.is_action_just_pressed("attraper"):
		if objet_vise and objets_portes.size() < emplacements_objets.size():
			if !objets_portes.is_empty():
				objets_portes.back().outline.hide()
			objet_vise.desactivation_portee()
			objet_vise.reparent(%Bras)
			objet_vise.global_transform = emplacements_objets[objets_portes.size()].global_transform
			objets_portes.append(objet_vise)
			objet_vise = null
			%ItemPrompt.text = ""
	if Input.is_action_just_pressed("poser"):
		if objets_portes.size() > 0:
			if %RayCast3D.is_colliding():
				if simu_pose:
					simu_pose.queue_free()
					simu_pose = null
				var objet_lache: Objet = objets_portes.pop_back()
				if !objets_portes.is_empty():
					objets_portes.back().outline.show()
				objet_lache.outline.hide()
				objet_lache.reparent(%BoiteObjets)
				objet_lache.global_position = %RayCast3D.get_collision_point() + Vector3.UP * 0.01
				objet_lache.linear_velocity = Vector3.ZERO
				objet_lache.reactivation_lache()
func _process(delta: float) -> void:
	if rotacite and Input.is_action_pressed("tourner") and !objets_portes.is_empty():
		objets_portes.back().rotate_y(-delta * rotacite.x * sensi_regard)
		objets_portes.back().rotate_x(delta * rotacite.y * sensi_regard)
		if simu_pose:
			simu_pose.rotate_y(-delta * rotacite.x * sensi_regard)
			simu_pose.rotate_x(delta * rotacite.y * sensi_regard)
		rotacite = Vector2.ZERO
	elif rotacite:
		rotate_y(-delta * rotacite.x * sensi_regard)
		%Camera3D.rotate_x(delta * rotacite.y * sensi_regard)
		rotacite = Vector2.ZERO
	
	if %RayCast3D.is_colliding():
		var collider = %RayCast3D.get_collider()
		if collider is Objet and objets_portes.size() < emplacements_objets.size():
			collider.outline.show()
			if objet_vise != collider and objet_vise:
				objet_vise.outline.hide()
			objet_vise = collider
			%ItemPrompt.text = %ItemPrompt.format + objet_vise.nom
		elif collider is StaticBody3D:
			if !objets_portes.is_empty() and !simu_pose:
				simu_pose = objets_portes.back().duplicate()
				add_child(simu_pose)
				simu_pose.simulation()
				simu_pose.global_position = %RayCast3D.get_collision_point() + Vector3.UP * 0.01
			elif simu_pose:
				simu_pose.global_position = %RayCast3D.get_collision_point() + Vector3.UP * 0.01
				
	elif objet_vise or simu_pose:
		if objet_vise:
			objet_vise.outline.hide()
			objet_vise = null
			%ItemPrompt.text = ""
		if simu_pose:
			simu_pose.queue_free()
			simu_pose = null
	
	# DEPLACEMENTS
	if is_on_floor():
		if in_air:
			in_air = false
			velocity.y = 0.0
		
		var mi = get_move_input()
		mi = Vector3(mi.x, 0.0, mi.y)
		mi = mi.x * basis.x + mi.z * basis.z
		
		if mi:
			var vitesse_actuelle = vitesse
			if crouched:
				vitesse_actuelle = vitesse_crouched
			elif Input.is_action_pressed("sprint"):
				if index_sprint < 1.0:
					vitesse_actuelle = lerpf(vitesse, pic_sprint, index_sprint)
					index_sprint += delta * prog_sprint
				else:
					vitesse_actuelle = pic_sprint
			else:
				index_sprint = 0.0
			appliquer_force(mi * vitesse_actuelle)
		
		if Input.is_action_just_pressed("saut"):
			appliquer_impulse((Vector3.UP) * puissance_saut)
		
		appliquer_frottements(delta)
		
	else:
		in_air = true
	
	appliquer_force(Vector3(0, -force_grav, 0))
	appliquer_acceleration(delta)
	
	
