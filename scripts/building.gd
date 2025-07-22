extends Node3D

var wall_lengths := []

const FINE_INCREMENT := 0.25 #0.25
const AXIS_LOCK_THRES := 2.0

var stored_cell_size : float

#var object_pool : ObjectPool
var object_pool : Node
var object_pool_class : CSharpScript

@onready var stories_handler: Node = %StoriesHandler
@onready var multimesh_handler: Node = %MultimeshHandler

@onready var wall_story_container: Node3D = %WallStoryContainer
@onready var floor_story_container: Node3D = %FloorStoryContainer
@onready var appliance_story_container: Node3D = %ApplianceStoryContainer

@onready var multimesh_story_container: Node3D = %MultiMeshStoryContainers
var mm_story_free_container : Node3D
var mm_wall_story_container : Node3D
var mm_floor_story_container : Node3D

@onready var camera : Camera3D = %Camera3D
@onready var message : Message = %Message

@onready var w_hold : Node3D = %WallMarkerHold
@onready var w_draw : Node3D = %WallMarkerDraw
@onready var w_delete: Node3D = %WallMarkerDelete

enum AXIS_LOCK {
	X,
	Z,
	NONE,
}

var locked_axis = AXIS_LOCK.NONE

var occ_walls_arr := []
var occ_floors_arr := [] #Array of dictionaries to keep track of walls and floors
var occ_appliance_arr := [] #For appliances

var start_grid: Vector2i
var cur_grid: Vector2i

var is_deleting := false
var is_painting := false
var is_drawing := false

var cur_color : Color = Color.AZURE
@onready var temp_col_mat : StandardMaterial3D = StandardMaterial3D.new()

signal is_saving()

var is_building : bool
signal is_building_changed(new_value: bool)

var cur_category_index: int = 0
var cur_segment_index: int = 0

var floor_cat_index: int
var floor_index : int
var appliance_cat_index : int
var stairs_cat_index : int
var roof_cat_index : int

var single_segment_categories := []

var cell_size := 1.0

func _ready() -> void:
	
	w_draw.show()
	append_new_dict() #Initial dictionaries and containers
	add_scenes()
	
	single_segment_categories = [appliance_cat_index, stairs_cat_index]
	
	load_segments()

func load_segments() -> void:
	var max_stories : int = config.load_loading_settings("max_stories")
	for i in range(max_stories):
		append_new_dict()
		stories_handler.max_stories += 1
	
	var wall_saver := WallSaver.new()
	
	wall_saver.load_occ_dict(occ_floors_arr,
							"building_floors/",
							floor_story_container,
							object_pool)
	wall_saver.load_occ_dict(occ_walls_arr,
							"building_walls/",
							wall_story_container,
							object_pool)
	wall_saver.load_occ_dict(occ_appliance_arr,
							"building_appliances/",
							appliance_story_container,
							object_pool)

func start_building(building: bool) -> void:
	if building:
		is_building = true
		emit_signal("is_building_changed", is_building)
		
		multimesh_story_container.hide()
		wall_story_container.show()
		floor_story_container.show()
		
	else:
		is_building = false
		emit_signal("is_building_changed", is_building)
		
		multimesh_story_container.show()
		wall_story_container.hide()
		floor_story_container.hide()

func add_scenes() -> void:
	
	object_pool_class = load("res://scripts/object_pool.cs")
	object_pool = object_pool_class.new()
	
	#CATEGORY 0 WALLS ------------------
	var wall_scenes: Array[PackedScene] = [
		preload("res://scenes/Segments/wall_1.tscn"),
		preload("res://scenes/Segments/wall_1_door.tscn"),
		preload("res://scenes/Segments/wall_1_window.tscn"),
		preload("res://scenes/Segments/wall_05.tscn"),
		preload("res://scenes/Segments/wall_025.tscn"),
		preload("res://scenes/Segments/wall_1_triangle.tscn")
	]
	
	object_pool.preload_scenes(wall_scenes, -1)
	
	var length_category_0 := []
	length_category_0.append(1.0)
	length_category_0.append(1.0)
	length_category_0.append(1.0)
	length_category_0.append(0.5)
	length_category_0.append(0.25)
	length_category_0.append(1.0)
	wall_lengths.append(length_category_0)
	#----------------------------------
	
	#CATEGORY 1 FLOORS ----------------
	var floor_scenes: Array[PackedScene] = [
		preload("res://scenes/Segments/Floor_1.tscn"), #Change later to 1M
		preload("res://scenes/Segments/Floor_05.tscn") #Change later to 50cm
	]
	
	floor_cat_index = object_pool.preload_scenes(floor_scenes, -1)
	floor_index = object_pool.preload_unlimited_scene(preload("res://scenes/Segments/Floor_025.tscn"), object_pool.get_size()-1)
	
	var length_category_1 := []
	length_category_1.append(1.0)
	length_category_1.append(0.5)
	length_category_1.append(0.25)
	wall_lengths.append(length_category_1)
	#----------------------------------
	
	#CATEGORY 2 STAIRS ----------------
	var stair_scenes: Array[PackedScene] = [
		preload("res://scenes/Segments/stairs_1.tscn"),
		preload("res://scenes/Segments/stairs_1_banister.tscn")
	]
	
	stairs_cat_index = object_pool.preload_scenes(stair_scenes, -1)
	
	var length_category_2 := []
	length_category_2.append(0.25)
	length_category_2.append(0.25)
	wall_lengths.append(length_category_2)
	#---------------------------------
	
	#CATEGORY 3 ROOFS -----------------
	var roof_scenes: Array[PackedScene] = [
		preload("res://scenes/Segments/roof_1.tscn")
	]
	
	roof_cat_index = object_pool.preload_scenes(roof_scenes, -1)
	
	var length_category_3 := []
	length_category_3.append(1.0)
	wall_lengths.append(length_category_3)
	#---------------------------------
	
	#CATEGORY 4 APPLIANCES -----------
	var appliance_scenes: Array[PackedScene] = [
		preload("res://scenes/Appliances/refrigerator.tscn"),
		preload("res://scenes/Appliances/oven.tscn"),
		preload("res://scenes/Appliances/washer_dryer.tscn")
	]
	
	appliance_cat_index = object_pool.preload_scenes(appliance_scenes, -1)
	
	var length_category_4 := []
	length_category_4.append(0.5)
	length_category_4.append(0.5)
	length_category_4.append(0.5)
	wall_lengths.append(length_category_4)
	#---------------------------------

func combine_meshes() -> void: #Combine meshes as multi mesh for reduced drawcalls
	
	emit_signal("is_saving")
	
	if occ_walls_arr[stories_handler.current_story].is_empty() and occ_floors_arr[stories_handler.current_story].is_empty():
		return #Avoid uneccesary loops
	
	mm_story_free_container = multimesh_story_container.get_child(0)
	
	if mm_story_free_container:
		mm_story_free_container.queue_free() #Free the previous multimeshes

	mm_story_free_container = Node3D.new()
	multimesh_story_container.add_child(mm_story_free_container)
	
	var wall_saver := WallSaver.new()
	
	mm_wall_story_container = Node3D.new()
	mm_story_free_container.add_child(mm_wall_story_container)
	
	mm_floor_story_container = Node3D.new()
	mm_story_free_container.add_child(mm_floor_story_container)
	
	clear_directory("user://save_data/mm_data/mm_walls/backup", false) #clear the backup directory without creating new backup
	clear_directory("user://save_data/mm_data/mm_walls/")
	
	var wall_mm_isok : bool = multimesh_handler.add_mm_to_scene_and_save(occ_walls_arr.size(),
							mm_wall_story_container,
							occ_walls_arr,
							"wall_batch_%d_%d.res",
							"mm_walls/")
	
	if !wall_mm_isok:
		message.set_message("Error batching walls!")
		clear_directory("user://save_data/mm_data/mm_walls/", false)
		move_backup_files_up("user://save_data/mm_data/mm_walls/backup")
	
	clear_directory("user://save_data/building_data/building_walls/backup", false) #clear the backup directory
	clear_directory("user://save_data/building_data/building_walls/")
	
	var wall_isok : bool = wall_saver.save_occ_dict(occ_walls_arr.size(),
				occ_walls_arr,
				"wall_building_%d.json",
				"building_walls/")
	
	if !wall_isok:
		message.set_message("Error saving walls!")
		clear_directory("user://save_data/building_data/building_walls/", false)
		move_backup_files_up("user://save_data/building_data/building_walls/backup")
	
	clear_directory("user://save_data/mm_data/mm_floors/backup", false)  #clear the backup directory
	clear_directory("user://save_data/mm_data/mm_floors/")
	
	var floor_mm_isok : bool = multimesh_handler.add_mm_to_scene_and_save(occ_floors_arr.size(),
							mm_floor_story_container,
							occ_floors_arr,
							"floor_batch_%d_%d.res",
							"mm_floors/")
	
	if !floor_mm_isok:
		message.set_message("Error batching floors!")
		clear_directory("user://save_data/mm_data/mm_floors/", false)
		move_backup_files_up("user://save_data/mm_data/mm_floors/backup")
	
	clear_directory("user://save_data/building_data/building_floors/backup", false)  #clear the backup directory
	clear_directory("user://save_data/building_data/building_floors/")
	
	var floor_isok : bool = wall_saver.save_occ_dict(occ_floors_arr.size(),
				occ_floors_arr,
				"floor_building_%d.json",
				"building_floors/")
	
	if !floor_isok:
		message.set_message("Error saving floors!")
		clear_directory("user://save_data/building_data/building_floors/", false)
		move_backup_files_up("user://save_data/building_data/building_floors/backup")
	
	#---------------------------------------------
	#Save the appliances
	
	clear_directory("user://save_data/building_data/building_appliances/backup", false)  #clear the backup directory
	clear_directory("user://save_data/building_data/building_appliances/")

	var appliance_isok : bool = wall_saver.save_occ_dict(occ_appliance_arr.size(),
					occ_appliance_arr,
					"appliance_building_%d.json",
					"building_appliances/")
	
	if !appliance_isok:
		message.set_message("Error saving appliances!")
		clear_directory("user://save_data/building_data/building_appliances/", false)
		move_backup_files_up("user://save_data/building_data/building_appliances/backup")
	
	#---------------------------------------------
	
	config.save_loading_settings("max_stories", stories_handler.max_stories)
	
	if wall_isok and wall_mm_isok and floor_isok and floor_mm_isok and appliance_isok:
		message.set_message("Saved and batched walls successfully")

func clear_directory(path : String, will_backup := true) -> void:
	if !path.begins_with("user://save_data/"):
		print("DANGER, don't attempt to delete anything other than save data!")
		return
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Directory not found: " + path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var file_path := path + "/" + file_name
			
			if will_backup:
				var backup_file_path := path + "/backup/" + file_name
				backup_file(file_path, backup_file_path)
				
			DirAccess.remove_absolute(file_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func move_backup_files_up(backup_dir: String) -> void:
	var dir := DirAccess.open(backup_dir)
	if dir == null:
		push_error("Failed to open backup directory: %s" % backup_dir)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var source_path = backup_dir + "/" + file_name
			var parent_dir = backup_dir.get_base_dir()
			var destination_path = parent_dir + "/" + file_name
			
			var err := DirAccess.copy_absolute(source_path, destination_path)
			if err != OK:
				push_error("Failed to move file: %s" % file_name)
			#else:
				#DirAccess.remove_absolute(source_path) #Clear the backup files? Yes? No?
		
		file_name = dir.get_next()
	dir.list_dir_end()

func backup_file(path : String, backup_path: String) -> void:
	var original_file := FileAccess.open(path, FileAccess.READ)
	if !original_file:
		return
		
	var new_file := FileAccess.open(backup_path, FileAccess.WRITE)
	if !new_file:
		return
		
	var data := original_file.get_buffer(original_file.get_length())
	new_file.store_buffer(data)
			
	original_file.close()
	new_file.close()

func _process(_delta: float) -> void:
	
	cur_grid = world_to_grid(get_mouse_world_position())
	
	if is_drawing:
		match locked_axis:
			AXIS_LOCK.NONE:
				var delta = cur_grid - start_grid
				if abs(delta.x) >= AXIS_LOCK_THRES or abs(delta.y) >= AXIS_LOCK_THRES:
					if abs(delta.x) > abs(delta.y):
						locked_axis = AXIS_LOCK.X
					else:
						locked_axis = AXIS_LOCK.Z
			AXIS_LOCK.X:
				cur_grid.y = start_grid.y
			AXIS_LOCK.Z:
				cur_grid.x = start_grid.x
		
		w_hold.position = grid_to_world(cur_grid)
	else:
		w_draw.position = grid_to_world(cur_grid)

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("remove_wall"):
		is_deleting = true
		w_delete.show()
	
	if event.is_action_pressed("place_wall") or event.is_action_pressed("remove_wall"):
		start_grid = world_to_grid(get_mouse_world_position())
		is_drawing = true
		
		w_hold.position = grid_to_world(start_grid)
		w_hold.show()
		
		locked_axis = AXIS_LOCK.NONE

	elif event.is_action_released("place_wall") or event.is_action_released("remove_wall"):
		set_axis_lock(cur_grid)
		
		draw_line(start_grid, cur_grid)
			
		is_drawing = false
		w_hold.hide()
		is_deleting = false
		w_delete.hide()
		locked_axis = AXIS_LOCK.NONE

func set_axis_lock(grid_pos)-> void:
	if locked_axis == AXIS_LOCK.X:
		grid_pos.y = start_grid.y
	elif locked_axis == AXIS_LOCK.Z:
		@warning_ignore("standalone_expression")
		grid_pos.x == start_grid.x

func get_mouse_world_position() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	
	var result = space_state.intersect_ray(query)
	return result["position"] if result.has("position") else Vector3.ZERO

func world_to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size), floor(pos.z / cell_size))

func grid_to_world(grid: Vector2i) -> Vector3:
	return Vector3(grid.x * cell_size, 0 + stories_handler.FLOOR_HEIGHT * stories_handler.current_story, grid.y * cell_size)

func start_end_to_dir_f(end: Vector2i, start: Vector2i) -> Vector2:
	return Vector2(end - start).normalized()

func calculate_fine_steps(start: Vector2i, end: Vector2i) -> int:
	return int((end - start).length() / FINE_INCREMENT) + 1

func draw_line(start: Vector2i, end: Vector2i) -> void:
	if start == end: #Base case
		return

	if start.x != end.x and start.y != end.y: #Base case
		return

	var dir_f: Vector2 = start_end_to_dir_f(end, start)
	var steps = abs((end - start).x + (end - start).y) # Either x or y will be zero
	
	if is_deleting and not is_painting:
		delete_segments(start, dir_f, steps)
	elif is_painting or (is_painting and is_deleting):
		paint_segments(start, dir_f, steps)
	elif cur_category_index in single_segment_categories:
		place_segment(end, dir_f)
	else:
		place_segments(start, dir_f, steps)

func delete_segments(start: Vector2, dir_f: Vector2, steps: int) -> void:
	var fine_steps := calculate_fine_steps(start, start + dir_f * steps)
	var current: Vector2 = Vector2(start)
	
	for i: int in range(fine_steps):
		match cur_category_index:
			floor_cat_index:
				delete_floor_segment(current)
			appliance_cat_index:
				delete_appliance_segment(current)
			_:
				delete_wall_segment(current.floor(), dir_f)
		current += dir_f * FINE_INCREMENT
	
	message.set_message(str("Deleted segments between ", start, " and ", start + dir_f * steps))

func paint_segments(start: Vector2, dir_f: Vector2, steps: int) -> void:
	var fine_steps := calculate_fine_steps(start, start + dir_f * steps)
	var current: Vector2 = Vector2(start)
	
	for i: int in range(fine_steps):
		paint_segment(current, dir_f)
		current += dir_f * FINE_INCREMENT

func place_segments(start: Vector2i, dir: Vector2i, steps: int) -> void:
	var current: Vector2i = start + dir
	
	for i in range(int(steps)):
		place_segment(current, dir)
		current += dir

func delete_wall_segment(grid_pos: Vector2i, dir: Vector2i) -> void:
	var wall_key = make_wall_key(grid_pos, dir)
	if occ_walls_arr[stories_handler.current_story].has(wall_key):
		var wall_node : Node3D = occ_walls_arr[stories_handler.current_story][wall_key]
		wall_node = reset_transform(wall_node)
		
		wall_story_container.get_child(stories_handler.current_story).remove_child(wall_node)
		object_pool.return_instance(wall_node)
		occ_walls_arr[stories_handler.current_story].erase(wall_key)

func delete_floor_segment(grid_pos: Vector2) -> void:
	var floor_key := make_floor_key(grid_pos)
	if occ_floors_arr[stories_handler.current_story].has(floor_key):
		var floor_node : Node3D = occ_floors_arr[stories_handler.current_story][floor_key]
		floor_node = reset_transform(floor_node)
		
		floor_story_container.get_child(stories_handler.current_story).remove_child(floor_node)
		object_pool.return_instance(floor_node)
		occ_floors_arr[stories_handler.current_story].erase(floor_key)

func delete_appliance_segment(grid_pos: Vector2) -> void:
	var appliance_key := make_floor_key(grid_pos)
	if occ_appliance_arr[stories_handler.current_story].has(appliance_key):
		var appliance_node : Node3D = occ_appliance_arr[stories_handler.current_story][appliance_key]
		appliance_node = reset_transform(appliance_node)
		
		appliance_story_container.get_child(stories_handler.current_story).remove_child(appliance_node)
		object_pool.return_instance(appliance_node)
		occ_appliance_arr[stories_handler.current_story].erase(appliance_key)

func paint_segment(grid_pos: Vector2, dir: Vector2i) -> void:
	var node : Node3D
	
	if cur_category_index != floor_cat_index:
		var wall_key := make_wall_key(grid_pos, dir)
		if occ_walls_arr[stories_handler.current_story].has(wall_key):
			node = occ_walls_arr[stories_handler.current_story][wall_key]
	else:
		var floor_key := make_floor_key(grid_pos)
		if occ_floors_arr[stories_handler.current_story].has(floor_key):
			node = occ_floors_arr[stories_handler.current_story][floor_key]
	if node:
		var mesh : MeshInstance3D = node.get_child(0)
		if is_deleting:
			if !mesh.has_meta("color"):
				return
			mesh.set_meta("color", Color.WHITE)
		else:
			mesh.set_meta("color", cur_color)
			
			mesh.material_override = temp_col_mat
			await get_tree().create_timer(1.0).timeout
			mesh.material_override = null

func set_color(col: Color) -> void:
	cur_color = col
	temp_col_mat.albedo_color = cur_color

func place_segment(grid_pos: Vector2i, dir: Vector2i):
	var segment_inst: Node3D = object_pool.get_instance(cur_segment_index, cur_category_index)
	
	if !segment_inst:
		print("Pooling limit reached!")
		message.set_message("Pooling limit reached!")
		return
		
	var world_pos: Vector3 = grid_to_world(grid_pos)
	var half_cell := cell_size/2
	
	var wall_key := make_wall_key(grid_pos, dir)
	var floor_key := make_floor_key(grid_pos)
	var appliance_key := make_floor_key(grid_pos)
	
	if occ_walls_arr[stories_handler.current_story].has(wall_key) and cur_category_index != floor_cat_index:
		print("Wallspace ", grid_pos, " occupied!")
		message.set_message(str("Wallspace ", grid_pos, " occupied!"))
		return
	elif occ_floors_arr[stories_handler.current_story].has(floor_key) and cur_category_index == floor_cat_index:
		print("Floorspace ", grid_pos, " occupied!")
		message.set_message(str("Floorspace ", grid_pos, " occupied!"))
		return
	elif occ_appliance_arr[stories_handler.current_story].has(appliance_key) and cur_category_index == appliance_cat_index:
		message.set_message(str("Appliance-Space ", grid_pos, " occupied!"))
		return
	
	if dir.x != 0:
		segment_inst.rotation.y += deg_to_rad(90)
	
	if dir.x > 0:
		world_pos -= Vector3(half_cell, 0, 0)
		segment_inst.get_child(0).rotation.y = deg_to_rad(0)
	elif dir.x < 0:
		world_pos += Vector3(half_cell, 0, 0)
		segment_inst.get_child(0).rotation.y = deg_to_rad(-180)
	elif dir.y > 0:
		world_pos -= Vector3(0, 0, half_cell)
		segment_inst.get_child(0).rotation.y = deg_to_rad(0)
	else:
		world_pos += Vector3(0, 0, half_cell)
		segment_inst.get_child(0).rotation.y = deg_to_rad(-180)
	
	segment_inst.position = world_pos
	
	match cur_category_index:
		floor_cat_index:
			occ_floors_arr[stories_handler.current_story][floor_key] = segment_inst
			
			floor_story_container.get_child(stories_handler.current_story).add_child(segment_inst)
			
			print("Placed Floor: ", cell_size, " at ", segment_inst.position)
		appliance_cat_index:
			occ_appliance_arr[stories_handler.current_story][appliance_key] = segment_inst
			
			appliance_story_container.get_child(stories_handler.current_story).add_child(segment_inst)
			
			print("Placed Appliance: ", cell_size, " at ", segment_inst.position)
		_:
			occ_walls_arr[stories_handler.current_story][wall_key] = segment_inst
			
			wall_story_container.get_child(stories_handler.current_story).add_child(segment_inst)
			
			print("Placed Wall: ", cell_size, " at ", segment_inst.position)

func check_if_floorable()-> void:
	clear_floors()
	
	if occ_walls_arr[stories_handler.current_story].is_empty():
		return
	
	stored_cell_size = cell_size
	cell_size = FINE_INCREMENT
	
	var keys = occ_walls_arr[stories_handler.current_story].keys()
	
	for entry in keys:
		if get_axis_from_wall_key(entry) == "x":
			continue
		
		var wall_node = occ_walls_arr[stories_handler.current_story][entry]
		
		var ray_array : Array
		
		if wall_node.get_node("Rays"):#Find a way to check for roofs pass on the category 
			ray_array = wall_node.get_node("Rays").get_children()
		
		for ray : RayCast3D in ray_array:
			ray.force_raycast_update()
			if ray.is_colliding():
				place_flooring(world_to_grid(wall_node.position + ray.position), world_to_grid(ray.get_collision_point()))
	
	message.set_message("Automatically placed flooring")
	cell_size = stored_cell_size

func place_flooring(start: Vector2i, end: Vector2i):
	var fine_steps := calculate_fine_steps(start, end)
	if fine_steps <= 0: return
	
	var dir_f: Vector2 = start_end_to_dir_f(end, start)
	var current : Vector2 = Vector2(start)
	
	for i: int in range(fine_steps):
		var floor_key := make_floor_key(current)
		if occ_floors_arr[stories_handler.current_story].has(floor_key):
			break
		
		var floor_inst: Node3D = object_pool.get_instance(floor_index, floor_cat_index)
		occ_floors_arr[stories_handler.current_story][floor_key] = floor_inst
		
		floor_inst.position = grid_to_world(current) + Vector3(FINE_INCREMENT/2, 0, 0)
		
		floor_story_container.get_child(stories_handler.current_story).add_child(floor_inst)
		
		current += dir_f * FINE_INCREMENT

func make_wall_key(grid_pos: Vector2i, dir: Vector2i) -> String:
	var axis := "x" if dir.x != 0 else "z" #Converts the positional info and current floor into a string
	return "%d,%d:%s" % [grid_pos.x, grid_pos.y, axis] #For dictionary

func make_floor_key(grid_pos: Vector2) -> String:
	return "%f,%f" % [grid_pos.x, grid_pos.y]

func get_axis_from_wall_key(wall_key: String) -> String:
	var parts = wall_key.split(":")
	if parts.size() == 2:
		return parts[1]
	return ""

func set_category(index : int):
	cur_category_index = index

func set_wall_type(index: int):
	cur_segment_index = index
	cell_size = wall_lengths[cur_category_index][cur_segment_index]

func append_new_dict() -> void:
	
	var occ_walls := {}
	occ_walls_arr.append(occ_walls)
	
	var occ_floors := {}
	occ_floors_arr.append(occ_floors)
	
	var occ_appliances := {}
	occ_appliance_arr.append(occ_appliances)
	
	var floor_container : Node3D = Node3D.new()
	floor_story_container.add_child(floor_container)
	
	var wall_container : Node3D = Node3D.new()
	wall_story_container.add_child(wall_container)
	
	var appliance_container : Node3D = Node3D.new()
	appliance_story_container.add_child(appliance_container)

func show_marker(showing):
	if showing:
		w_draw.show()
	else:
		w_hold.hide()
		w_delete.hide()
		w_draw.hide()

func clear_walls() -> void:
	if occ_walls_arr[stories_handler.current_story].is_empty():
		print("No walls to clear!")
		return
	
	var keys = occ_walls_arr[stories_handler.current_story].keys()
	
	for entry in keys:
		var wall_node = occ_walls_arr[stories_handler.current_story][entry]
		wall_node = reset_transform(wall_node)
		
		wall_story_container.get_child(stories_handler.current_story).remove_child(wall_node)
		object_pool.return_instance(wall_node)
		
	occ_walls_arr[stories_handler.current_story].clear()
	
	message.set_message("Cleared all floors and walls")

func clear_floors() -> void:
	if occ_floors_arr[stories_handler.current_story].is_empty():
		print("No floors to clear!")
		return
	
	var keys = occ_floors_arr[stories_handler.current_story].keys()
	
	for entry in keys:
		var floor_node = occ_floors_arr[stories_handler.current_story][entry]
		floor_node = reset_transform(floor_node)
		
		floor_story_container.get_child(stories_handler.current_story).remove_child(floor_node)
		object_pool.return_instance(floor_node)
		
	occ_floors_arr[stories_handler.current_story].clear()

func clear_appliances() -> void:
	if occ_appliance_arr[stories_handler.current_story].is_empty():
		print("No appliances to clear!")
		return
	
	var keys = occ_appliance_arr[stories_handler.current_story].keys()
	
	for entry in keys:
		var appliance_node = occ_appliance_arr[stories_handler.current_story][entry]
		appliance_node = reset_transform(appliance_node)
		
		appliance_story_container.get_child(stories_handler.current_story).remove_child(appliance_node)
		object_pool.return_instance(appliance_node)
		
	occ_appliance_arr[stories_handler.current_story].clear()

func undo() -> void:
	var keys
	
	match cur_category_index:
		floor_cat_index:
			if occ_floors_arr[stories_handler.current_story].is_empty():
				print("No floors to undo!")
				message.set_message("No floors to undo!")
				return
			
			keys = occ_floors_arr[stories_handler.current_story].keys()
			keys.reverse()
			var floor_node = occ_floors_arr[stories_handler.current_story][keys.get(0)]
			floor_node = reset_transform(floor_node)
			
			floor_story_container.get_child(stories_handler.current_story).remove_child(floor_node)
			object_pool.return_instance(floor_node)
			
			print("Undo Floor", keys.get(0))
			message.set_message(str("Undo Floor ", keys.get(0)))
			occ_floors_arr[stories_handler.current_story].erase(keys.get(0))
		appliance_cat_index:
			if occ_appliance_arr[stories_handler.current_story].is_empty():
				print("No appliances to undo!")
				message.set_message("No appliances to undo!")
				return
				
			keys = occ_appliance_arr[stories_handler.current_story].keys()
			keys.reverse()
			var appliance_node = occ_appliance_arr[stories_handler.current_story][keys.get(0)]
			appliance_node = reset_transform(appliance_node)
			
			appliance_story_container.get_child(stories_handler.current_story).remove_child(appliance_node)
			object_pool.return_instance(appliance_node)
			
			print("Undo Appliance", keys.get(0))
			message.set_message(str("Undo Appliance ", keys.get(0)))
			occ_appliance_arr[stories_handler.current_story].erase(keys.get(0))
		_:
			if occ_walls_arr[stories_handler.current_story].is_empty():
				print("No walls to undo!")
				message.set_message("No walls to undo!")
				return
				
			keys = occ_walls_arr[stories_handler.current_story].keys()
			keys.reverse()
			var wall_node = occ_walls_arr[stories_handler.current_story][keys.get(0)]
			wall_node = reset_transform(wall_node)
			
			wall_story_container.get_child(stories_handler.current_story).remove_child(wall_node)
			object_pool.return_instance(wall_node)
			
			print("Undo Wall", keys.get(0))
			message.set_message(str("Undo Wall ", keys.get(0)))
			occ_walls_arr[stories_handler.current_story].erase(keys.get(0))

func reset_transform(node : Node3D) -> Node3D:
	node.rotation = Vector3(0,0,0)
	node.get_child(0).rotation = Vector3(0,0,0)
	node.get_child(0).set_meta("color", Color.WHITE)
	node.position = Vector3(0,0,0)
	return node
