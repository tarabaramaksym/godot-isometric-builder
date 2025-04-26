class_name Highlight extends Node

var highlight_material: StandardMaterial3D
var buffer_material: StandardMaterial3D
var current_mesh: MeshInstance3D

func _ready():
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color(0.8, 0.8, 0.8)

	GlobalBuilding.selected_component_changed.connect(on_selected_component_changed)

func assign_highlight(component: Dictionary, static_body: StaticBody3D, component_mesh: MeshInstance3D):
	if component:
		print("Component: ", component.name)

		if "can_be_highlighted" in component:
			print("Can be highlighted: ", component.can_be_highlighted)

		if "can_be_highlighted" in component and component.can_be_highlighted:
			print("Assigning highlight to ", component.name)

	if component != null and "can_be_highlighted" in component and component.can_be_highlighted:
		print("Assigning highlight to ", component.name)
		static_body.mouse_entered.connect(on_mouse_entered.bind(component_mesh))
		static_body.mouse_exited.connect(on_mouse_exited.bind(component_mesh))

func on_mouse_entered(component_mesh: MeshInstance3D):
	print("GlobalBuilding.selected_component: ", GlobalBuilding.selected_component)
	if GlobalBuilding.selected_component:
		return

	print("Mouse entered ", component_mesh.name)
	buffer_material = component_mesh.material_override
	component_mesh.material_override = highlight_material
	current_mesh = component_mesh

func on_mouse_exited(component_mesh: MeshInstance3D):
	print("GlobalBuilding.selected_component: ", GlobalBuilding.selected_component)
	if GlobalBuilding.selected_component:
		return

	print("Mouse exited ", component_mesh.name)
	component_mesh.material_override = buffer_material

func on_selected_component_changed(value: String):
	if value and current_mesh != null:
		current_mesh.material_override = buffer_material
		current_mesh = null
