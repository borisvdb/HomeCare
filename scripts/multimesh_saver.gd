extends Node
class_name MultimeshSaver

func combine_instances_to_multimeshes(dictionary: Dictionary, story_index: int) -> Array:
	if dictionary.is_empty():
		return []
	
	var multimeshes := []
	var mesh_groups := {}
	
	var keys = dictionary.keys()
	
	for key in keys:
		var instance = dictionary[key]
		var child = instance.get_child(0)
		if child is MeshInstance3D and child.mesh:
			var mesh = child.mesh
			if not mesh_groups.has(mesh):
				mesh_groups[mesh] = []
			var entry = {
				"transform": child.global_transform,
				"color": child.get_meta("color")
			}
			mesh_groups[mesh].append(entry)
		else:
			print("Meshes in scene ", instance, " configured incorrectly!")
	
	for mesh in mesh_groups.keys():
		var multimesh = MultiMesh.new()
		multimesh.use_colors = true
		
		var instances = mesh_groups[mesh]
		var instance_count = instances.size()
		
		if instance_count == 0:
			continue # Skip if there are no transforms for this mesh
		
		multimesh.mesh = mesh
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = instance_count
		
		for i in range(instance_count):
			var entry = instances[i]
			multimesh.set_instance_transform(i, entry["transform"])
			multimesh.set_instance_color(i, entry["color"])
		
		multimesh.set_meta("story_index", story_index)
		multimeshes.append(multimesh)
	
	return multimeshes

func save_multimesh_to_file(multimesh: MultiMesh, file_path: String) -> bool:
	if multimesh == null:
		push_error("Multimesh is empty")
		return false
	
	var save_path = file_path
	if not save_path.ends_with(".res"):
		push_error("Incorrect extension, use .res " + save_path)
		return false
	
	var result = ResourceSaver.save(multimesh, save_path)
	if result != OK:
		push_error("Failed to save MultiMesh resource to " + save_path)
	else:
		print("Successfully saved MultiMesh to " + save_path)
	
	return true

func load_multimesh_resource(file_path: String) -> MultiMeshInstance3D:
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return null
	
	var loaded_multimesh = load(file_path)
	if loaded_multimesh == null or not (loaded_multimesh is MultiMesh):
		push_error("Failed to load MultiMesh from " + file_path)
		return null
	
	var multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = loaded_multimesh
	
	return multimesh_instance
