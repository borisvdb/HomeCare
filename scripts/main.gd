extends Node3D

@onready var building : Node3D = %Building
@onready var ui_building : CanvasLayer = %UI_Building
@onready var ui : CanvasLayer = %UI
@onready var gizmo : Node3D = %Gizmo
@onready var xray : MeshInstance3D = %XRay
@onready var ground_collision: StaticBody3D = %GroundCollision
@onready var multimesh_handler: Node = %MultimeshHandler
@onready var floor_plans : MeshInstance3D = %FloorPlans

@onready var gmesh_spec : MeshInstance3D = %GroundMesh_Spectating



func _ready() -> void:
	set_building_mode(false)
	set_xray_mode(false)
	
	multimesh_handler.load_mm_data()
	ui_building.reset_story()
	
	create_save_data_folders()
	
	if config.load_loading_settings("first_time"):
		%Welcome_Message.popup()
		await get_tree().create_timer(0.1).timeout
		config.save_loading_settings("first_time", 0)

func set_building_mode(is_building) -> void:
	if is_building:
		building.show_marker(true)
		building.set_process_input(true)
		building.set_process_unhandled_input(true)
		building.set_process(true)
		building.start_building(true)
		ui.hide_colour_swatches(true)
		ui_building.show()
		gizmo.show()
		ground_collision.show()
		floor_plans.show()
		
		gmesh_spec.hide()
	else:
		building.show_marker(false)
		building.set_process_input(false)
		building.set_process_unhandled_input(false)
		building.set_process(false)
		building.start_building(false)
		ui.hide_colour_swatches(false)
		ui_building.hide()
		gizmo.hide()
		ground_collision.hide()
		floor_plans.hide()
		
		gmesh_spec.show()

func set_xray_mode(is_xray) -> void:
	if is_xray:
		xray.show()
	else:
		xray.hide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("quit"):
		%ConfirmationDialog.show()

#Everything below can be recoded in C#

func create_save_data_folders() -> void:
	var dir_access = DirAccess.open("user://")
	
	var first_time_startup := false
	
	var save_data_path := "user://save_data/"
	if !dir_access.dir_exists(save_data_path):
		dir_access.make_dir(save_data_path)
		first_time_startup = true
		
	var paths := [
		["building_data", "building_floors", "backup"],
		["building_data", "building_walls", "backup"],
		["building_data", "building_appliances", "backup"],
		["mm_data", "mm_walls", "backup"],
		["mm_data", "mm_floors", "backup"]
	]
	
	for path in paths:
		generate_folders(path)
	
	var sql_handler : SQLHandler = SQLHandler.new()
	if !dir_access.dir_exists(sql_handler.DB_PATH):
		sql_handler.create_database()
	
	if first_time_startup:
		generate_default()
		config.save_loading_settings("max_stories", 2)
		building.load_segments()
		building.combine_meshes()
		call_deferred("reload_current_scene")

func reload_current_scene() -> void:
	get_tree().reload_current_scene()

func generate_default() -> void:
	copy_default_files(
	"res://default_building_data/building_floors/",
	"user://save_data/building_data/building_floors/")
	copy_default_files(
	"res://default_building_data/building_walls/",
	"user://save_data/building_data/building_walls/")
	copy_default_files(
	"res://default_building_data/building_appliances/",
	"user://save_data/building_data/building_appliances/")

func generate_folders(folders: Array):
	var dir_access = DirAccess.open("user://save_data/")
	if dir_access == null:
		push_error("Failed to open user directory.")
		return
	
	var full_path = "user://save_data/"
	
	for i in range(folders.size()):
		full_path += folders[i] + "/"  # Construct the full path
		if !dir_access.dir_exists(full_path):
			var result = dir_access.make_dir(full_path)  # Create the directory
			if result != OK:
				push_error("Failed to create folder: " + full_path)
			else:
				print("Created folder:", full_path)
	
	return

func copy_default_files(source_path: String, destination_path: String) -> void:
	#res://default_building_data/
	var dir_access := DirAccess.open(source_path)
	
	if dir_access == null:
		push_error("Default folder not found!")
		return
	
	dir_access.list_dir_begin()
	var file_name := dir_access.get_next()
	
	while file_name != "":
		var source_file = source_path + file_name
		var destination_file = destination_path + file_name
		
		var file = FileAccess.open(source_file, FileAccess.READ)
		if file:
			var data = file.get_as_text()
			file.close()
			
			var json_destination_file = FileAccess.open(destination_file, FileAccess.WRITE)
			if json_destination_file:
				json_destination_file.store_string(data)
				json_destination_file.close()
				print("Copied JSON file:", source_file, "to", destination_file)
			else:
				push_error("Failed to copy over file: " + source_file)
		file_name = dir_access.get_next()
	dir_access.list_dir_end()
