class_name GameObject extends Node3D

var game_object_id: String
var game_object_name: String

var static_body: StaticBody3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

var mesh_scene: Node3D

#TMP
var component_data: Dictionary
var current_size_values: Dictionary
#TMP end

func initialize_game_object(game_object_id_param: String, _parameters: Dictionary):
	self.game_object_id = game_object_id_param
	self.component_data = GlobalDataManager.get_game_object(game_object_id)

func handle_interaction(_interacter: Node3D, _parameters: Dictionary):
	pass

func setup_and_position_static_body(body_position: Vector3, param_rotation: float, current_size_values_param: Dictionary, shifted: bool = false):
	self.static_body = StaticBody3D.new()
	self.current_size_values = current_size_values_param
	
	create_mesh()
	set_game_object_position(body_position, param_rotation, shifted)
	create_material()
	create_collider()
	apply_root_properties()

	if !self.mesh_scene:
		self.static_body.add_child(self.mesh_instance)
	else:
		self.static_body.add_child(self.mesh_scene)

	self.static_body.add_child(self.collision_shape)

	self.add_child(self.static_body)

func create_mesh():
	var meshChild

	if component_data.mesh == "BoxMesh3D":
		meshChild = BoxMesh.new()
		
		var size = component_data.base_mesh_size
		var base_size = Vector3(size[0], size[1], size[2])
		
		meshChild.size = Vector3(
			current_size_values.get("x", base_size.x),
			current_size_values.get("y", base_size.y),
			current_size_values.get("z", base_size.z)
		)

		self.mesh_instance = MeshInstance3D.new()
		self.mesh_instance.mesh = meshChild
	elif component_data.mesh_type == "load":
		var mesh_path = component_data.mesh
		var model_scene = load(mesh_path)
		if model_scene:
			var model_instance = model_scene.instantiate()
			self.mesh_scene = model_instance

func set_game_object_position(body_position: Vector3, param_rotation: float, shifted: bool = false):
	self.transform.origin = body_position
	self.rotation_degrees.y = param_rotation
		
	if self.mesh_scene:
		# TODO: Temporary hardcoded positions
		self.transform.origin.y += 0.5
		self.mesh_scene.transform.origin.y -= 0.5
		return
	
	if not "position" in component_data and not shifted:
		# Half height offset to place bottom face at y=0
		self.transform.origin.y += (self.mesh_instance.mesh.size.y / 2)

func create_material():
	if self.mesh_scene:
		return

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8)

	if "rgb_color" in component_data:
		material.albedo_color = Color(
			component_data.rgb_color[0] / 255.0, 
			component_data.rgb_color[1] / 255.0, 
			component_data.rgb_color[2] / 255.0, 
			1.0
		)

	if "texture" in component_data:
		material.albedo_texture = load(component_data.texture)
		#material.albedo_texture.repeat = Vector2(1, 1)
		#material.albedo_texture.filter_mode = Texture.FILTER_NEAREST
		

	if self.mesh_scene:
		var children = self.mesh_scene.get_children()
		for child in children:
			if child is MeshInstance3D:
				child.material_override = material
	else:
		self.mesh_instance.material_override = material

func create_collider():
	if "collider" in component_data and component_data.collider == "simple":
		self.collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		
		var size = component_data.base_mesh_size
		var base_size = Vector3(size[0], size[1], size[2])

		shape.size = Vector3(
			current_size_values.get("x", base_size.x),
			current_size_values.get("y", base_size.y),
			current_size_values.get("z", base_size.z)
		)

		self.collision_shape.shape = shape
		self.collision_shape.transform.origin = Vector3(0, 0, 0)

	#highlight.assign_highlight(component_data, root_node, mesh_instance)

func apply_root_properties():
	if "scale" in component_data:
		self.mesh_instance.scale = component_data.scale

	if "rotation" in component_data:
		self.mesh_instance.rotation = component_data.rotation

func save() -> Dictionary:
	var current_size = self.mesh_instance.mesh.size

	var save_data = {
		"game_object_id": game_object_id,
		"position": {
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z
		},
		"rotation": {
			"y": rotation_degrees.y
		},
		"size_values": {
			"x": current_size.x,
			"y": current_size.y,
			"z": current_size.z
		},
		"type": "GameObject"
	}
	
	return save_data
	
func load_from_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos = Vector3(
			data.position.x,
			data.position.y,
			data.position.z
		)
		global_position = pos
	
	if data.has("rotation"):
		rotation_degrees.y = data.rotation.y
