extends Node
class_name WallSaver

func save_occ_dict(n : int, dict_arr: Array, file_name: String, folder: String) -> bool:
	
	var sql_handler : SQLHandler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()
	
	for i in range(n):
		if dict_arr[i].size() == 0:
			continue
		
		var serializable_dict := {}
		var keys = dict_arr[i].keys()
		
		for key in keys:
			var node : Node3D = dict_arr[i][key]
			
			var color : Color = node.get_child(0).get_meta("color")
			var col_hex = color.to_html(false)
			
			if !sql_handler.has_col(col_hex, i):
				sql_handler.insert_colour_data(col_hex, i)
			
			serializable_dict[key] = {
				"cat_index": node.get_meta("cat_index"), # You must ensure the scene is instanced from a known PackedScene
				"index": node.get_meta("index"),
				"position": node.position,
				"rotation": node.rotation,
				"mesh_rotation": node.get_child(0).rotation,
				"key": key,
				"story_index": i,
				"color": col_hex
			}
		
		var path := "user://save_data/building_data/" + folder + file_name % i
		var file := FileAccess.open(path, FileAccess.WRITE)
		
		if file == null:
			print("Failed to open file for writing: ", file)
			return false
		
		var json_string = JSON.stringify(serializable_dict)
		
		if json_string == null or json_string == "":
			push_error("Failed to serialize data to JSON.")
			file.close()
			return false
		
		var store_string = file.store_string(json_string)
		
		if !store_string:
			push_error("Failed to write to file: ", path)
			file.close()
			return false
		
		file.close()
	
	sql_handler.close_db()
	return true

func load_occ_dict(dict_arr: Array, folder: String, story_container: Node3D, object_pool: ObjectPool) -> bool:
	var path := "user://save_data/building_data/" + folder
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()

		while file != "":
			
			var file_path: String = path + "/" + file
			var file_access := FileAccess.open(file_path, FileAccess.READ)
			
			if file_access:
				var json_string = file_access.get_as_text()
				file_access.close()
				
				var json := JSON.new()
				var error = json.parse(json_string)
				
				if error != OK:
					push_error("Error parsing JSON: ", json_string)
					return false
				
				var serializable_dict: Dictionary = json.data
				var keys = serializable_dict.keys()
				
				for key in keys:
					
					var data = serializable_dict[key]
					
					var cat_index : int = data["cat_index"]
					var index : int = data["index"]
					var color: Color = Color(data["color"])
					
					var inst : Node3D = object_pool.get_instance(index, cat_index)
					if inst == null:
						push_error("Object pool instance is null!")
						return false
					
					inst.set_meta("cat_index", cat_index)
					inst.set_meta("index", index)
					inst.get_child(0).set_meta("color", color)
					
					inst.position = str_to_var("Vector3" + data["position"])
					inst.rotation = str_to_var("Vector3" + data["rotation"])
					inst.get_child(0).rotation = str_to_var("Vector3" + data["mesh_rotation"])
					
					var new_key : String = data["key"]
					var story_index : int = data["story_index"]
					
					dict_arr[story_index][new_key] = inst
					story_container.get_child(story_index).add_child(inst)
			file = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: " + path)
		return false
	
	return true
