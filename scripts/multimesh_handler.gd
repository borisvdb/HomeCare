extends Node

@onready var multimesh_story_container: Node3D = %MultiMeshStoryContainers
@onready var message : CanvasLayer = %Message

func add_mm_to_scene_and_save(n : int, container: Node3D, arr: Array, file_name: String, folder: String) -> bool:
	for i in range(n):
		var mesh_batcher = MultimeshSaver.new()
		var multimeshes: Array = mesh_batcher.combine_instances_to_multimeshes(arr[i], i)
		
		if multimeshes.is_empty():
			return true
		
		for j in range(multimeshes.size()):
			var multimesh_inst = MultiMeshInstance3D.new()
			multimesh_inst.multimesh = multimeshes[j]
			
			if i >= container.get_child_count():
				append_new_mm_containers(container)
			
			container.get_child(i).add_child(multimesh_inst)
			
			var path := "user://save_data/mm_data/"+ folder + file_name
			var mb = mesh_batcher.save_multimesh_to_file(
				multimeshes[j],
				path % [i, j],
			)
			
			if !mb:
				return false
			
	return true

func load_mm_data():
	var mm_story_free_container = Node3D.new()
	multimesh_story_container.add_child(mm_story_free_container)
	
	var mm_wall_story_container = Node3D.new()
	mm_story_free_container.add_child(mm_wall_story_container)
	
	var mm_path := "user://save_data/mm_data/mm_walls/"
	
	traverse_and_append_mm(mm_path, mm_wall_story_container)
	
	var mm_floor_story_container = Node3D.new()
	mm_story_free_container.add_child(mm_floor_story_container)
	
	mm_path = "user://save_data/mm_data/mm_floors/"
	
	traverse_and_append_mm(mm_path, mm_floor_story_container)

func traverse_and_append_mm(path: String, container: Node3D):
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var mesh_batcher = MultimeshSaver.new()
		while file_name != "":
			if not dir.current_is_dir():
				var full_path = path + file_name
				var mmi = mesh_batcher.load_multimesh_resource(full_path)
				
				var story_index : int
				if mmi:
					story_index = mmi.multimesh.get_meta("story_index")
				
				if story_index >= container.get_child_count():
					append_new_mm_containers(container)
				container.get_child(story_index).add_child(mmi)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: " + path)
		message.set_message("Failed to open directory: " + path)

func append_new_mm_containers(container: Node3D) -> void:
	
	var floor_container : Node3D = Node3D.new()
	container.add_child(floor_container)
	
	var wall_container : Node3D = Node3D.new()
	container.add_child(wall_container)
