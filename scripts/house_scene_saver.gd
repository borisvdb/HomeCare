extends Node
class_name HouseSceneSaver

var multimesh_story_container : Node3D
var house_root : Node3D
@onready var root := Node3D.new()

func initialize() -> void:
	multimesh_story_container = get_tree().root.get_node("Main").get_node("MultiMeshStoryContainers")
	house_root = multimesh_story_container.get_child(0)
	root = Node3D.new()
	root.name = "house_0"

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
			for mm in floor_.get_children():
				mm.owner = house_root
			f_i+=1
		t_i+=1

func save_house() -> void:
	
	var packed_scene := PackedScene.new()
	
	packed_scene.pack(house_root)
	
	var path := "user://save_data/my_test_scene_deletethis.tscn"
	
	var error = ResourceSaver.save(packed_scene, path)
	
	if error == OK:
		print("Scene saved to: ", path," successfully")
	else:
		push_error("Failed to save scene!")
