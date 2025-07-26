extends Node
class_name HouseSceneSaver

var stories_handler : Node
var multimesh_story_container : Node3D
var house_root : Node3D

var occ_floors_arr : Array
var occ_walls_arr : Array

const TILE_SIZE := 0.25

func initialize() -> void:
	multimesh_story_container = get_tree().root.get_node("Main").get_node("MultiMeshStoryContainers")
	house_root = multimesh_story_container.get_child(0)
	
	var building_node : Node3D = get_tree().root.get_node("Main").get_node("Building")
	occ_floors_arr = building_node.occ_floors_arr
	occ_walls_arr = building_node.occ_walls_arr
	
	stories_handler = get_tree().root.get_node("Main").get_node("StoriesHandler")

func set_mm_owner() -> void:
	var t_i := 0
	house_root.name = "house_0"
	for type in house_root.get_children():
		type.owner = house_root
		if t_i < 1:
			type.name = "walls"
		else:
			type.name = "floors"
		var f_i := 0
		for floor_ in type.get_children():
			floor_.owner = house_root
			floor_.name = "floor_%d" % [f_i]
			var m_i := 0
			for mm in floor_.get_children():
				mm.owner = house_root
				mm.name = "mm_%d" % [m_i]
				m_i+=1
			f_i+=1
		t_i+=1

func generate_floor_collision_shapes() -> void:
	var i := 0
	var floor_container = house_root.get_node("floors")
	for floor_ in floor_container.get_children():
		if floor_.get_child_count() == 0:
			continue
		
		var mm_instance_3d : MultiMeshInstance3D = floor_.get_child(0)
		var mm = mm_instance_3d.multimesh
		
		var local_aabb : AABB = mm.mesh.get_aabb()
		var combined_aabb: AABB
		
		for e in mm.instance_count:
			var xform: Transform3D = mm.get_instance_transform(e)
			
			for j in 8:
				var corner = local_aabb.get_endpoint(j)
				var world_point = xform * corner
				
				if combined_aabb == null:
					combined_aabb = AABB(world_point, Vector3.ZERO)
				else:
					combined_aabb = combined_aabb.expand(world_point)
		
		var shape := BoxShape3D.new()
		shape.size = Vector3(combined_aabb.size.x, 0.15, combined_aabb.size.z)
		
		var col_shape := CollisionShape3D.new()
		col_shape.transform.origin = combined_aabb.position + combined_aabb.size * 0.5
		col_shape.shape = shape
		col_shape.position.y = -0.075 + (stories_handler.FLOOR_HEIGHT * i)
		col_shape.name = "collision_%d" % i
		
		var static_body := StaticBody3D.new()
		static_body.name = "static_body_%d" % i
		static_body.add_child(col_shape)
		
		floor_.add_child(static_body)
		
		static_body.owner = house_root
		col_shape.owner = house_root
		
		i+=1

func generate_other_collision_shapes() -> void:
	var floor_container = house_root.get_node("walls")
	
	var i := 0
	for dict : Dictionary in occ_walls_arr:
		var keys = dict.keys()
		
		for key in keys:
			var node : Node3D = dict[key]
			var original_static_body : StaticBody3D = node.get_child(node.get_child_count()-1)
			var static_body : StaticBody3D = original_static_body.duplicate()
			
			floor_container.get_child(i).add_child(static_body)
			
			static_body.global_position = node.global_position
			var mesh : MeshInstance3D = node.get_child(0)
			var global_rotation_y = mesh.global_transform.basis.get_euler().y
			static_body.rotation.y = global_rotation_y
			
			static_body.owner = house_root
			for col in static_body.get_children():
				col.owner = house_root
			
		i+=1

func save_house() -> void:
	
	var packed_scene := PackedScene.new()
	
	packed_scene.pack(house_root)
	
	var path := "user://save_data/my_test_scene_deletethis.tscn"
	
	var error = ResourceSaver.save(packed_scene, path)
	
	if error == OK:
		print("Scene saved to: ", path," successfully")
	else:
		push_error("Failed to save scene!")
