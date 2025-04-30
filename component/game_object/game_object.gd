class_name GameObject extends Node3D

var game_object_id: String
var static_body: StaticBody3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

#TMP
var component_data: Dictionary
var current_size_values: Dictionary
#TMP end

func initialize_game_object(game_object_id_param: String, _parameters: Dictionary):
    self.game_object_id = game_object_id_param

func setup_and_position_static_body(body_position: Vector3, param_rotation: float, current_size_values_param: Dictionary):
    self.static_body = StaticBody3D.new()

    # data layer temporary!!!
    var building_components = GlobalFileBuilding.load_component_data().duplicate()
    building_components.merge(GlobalFileWorkstation.load_workstation_data())
    building_components.merge(GlobalFileNature.load_nature_data())

    component_data = building_components[game_object_id]
    self.current_size_values = current_size_values_param
    # TODO: remove temporary
    
    create_mesh()
    set_game_object_position(body_position, param_rotation)
    create_material()
    create_collider()
    
    self.static_body.add_child(self.collision_shape)
    self.static_body.add_child(self.mesh_instance)

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

func set_game_object_position(body_position: Vector3, param_rotation: float):
    self.transform.origin = body_position
    self.rotation_degrees.y = param_rotation
    
    if not "position" in component_data:
        # Half height offset to place bottom face at y=0
        self.transform.origin.y += (self.mesh_instance.mesh.size.y / 2)

func create_material():
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.8, 0.8, 0.8)

    if "rgb_color" in component_data:
        material.albedo_color = Color(
            component_data.rgb_color[0] / 255.0, 
            component_data.rgb_color[1] / 255.0, 
            component_data.rgb_color[2] / 255.0, 
            1.0
        )

    self.mesh_instance.material_override = material

func create_collider():
    if "collider" in component_data and component_data.collider == "simple":
        self.collision_shape = CollisionShape3D.new()
        var shape = BoxShape3D.new()
        shape.size = self.mesh_instance.mesh.size
        self.collision_shape.shape = shape
        self.collision_shape.transform.origin = Vector3(0, 0, 0)

    #highlight.assign_highlight(component_data, root_node, mesh_instance)



