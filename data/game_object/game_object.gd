extends RefCounted
class_name DataGameObject

enum SizingType {
    SINGLE,
	DIRECTIONAL,
	AREA
}

enum ColliderType {
    SIMPLE
}

enum MeshType {
    SIMPLE,
    LOAD
}

#region Game object info
var game_object_id: String
var game_object_name: String
var description: String
var icon_path: String
#endregion

#region Game object world properties
var sizing_type: SizingType
var collider_type: ColliderType
var mesh_type: MeshType
var mesh_path: String

var mesh_size: Vector3
var mesh_scale: Vector3
var mesh_rotation: Vector3
var minimum_height: int
var maximum_height: int 

# scene / mesh instance type depending on mesh type
var mesh
#endregion


func _init(game_object_id: String):
    # load all data from repository
    pass
    

