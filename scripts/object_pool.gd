extends Node
class_name ObjectPool

const MAX_INSTANCES: int = 100
var use_fixed_size := true #False for mobile and true for desktop
var preload_instances := false

var pool: Array = []

#preload a array of fixed or unlimited scenes
func preload_scenes(scenes: Array[PackedScene], cat_index: int = -1) -> int:
	if cat_index == -1:
		cat_index = pool.size()
		pool.append([])
	
	var category = pool[cat_index]
	category.clear()
	
	for index in range(scenes.size()):
		var scene := scenes[index]
		var instances: Array = []
		var preload_count = 0
		
		if preload_instances and MAX_INSTANCES > 0: #use_fixed_size
			preload_count = MAX_INSTANCES
		
		for i in range(preload_count):
			var inst = scene.instantiate()
			inst.visible = false
			inst.set_meta("cat_index", cat_index)
			inst.set_meta("index", index)
			inst.get_child(0).set_meta("color", Color.WHITE)
			instances.append(inst)
		
		category.append({
			"scene": scene,
			"instances": instances,
			"in_use": [],
			"max": MAX_INSTANCES,
			"use_fixed_size": use_fixed_size
		})
	
	return cat_index

func append_new_category() -> void:
	pool.append([])

#preload a single unlimited scene
func preload_unlimited_scene(scene: PackedScene, cat_index: int) -> int:
	var instances: Array = []
	var category = pool[cat_index]
	
	var inst = scene.instantiate()
	inst.visible = false
	
	inst.set_meta("cat_index", cat_index)
	inst.set_meta("index", category.size())
	inst.get_child(0).set_meta("color", Color.WHITE)
	
	instances.append(inst)
		
	category.append({
		"scene": scene,
		"instances": instances,
		"in_use": [],
		"max": MAX_INSTANCES,
		"use_fixed_size": false
	})
	
	return inst.get_meta("index")

#retrieve instance
func get_instance(index: int, cat_index: int) -> Node:
	if cat_index < pool.size() and index < pool[cat_index].size():
		var scene_data = pool[cat_index][index]

		if scene_data["instances"].size() > 0:
			var inst = scene_data["instances"].pop_back()
			scene_data["in_use"].append(inst)
			inst.visible = true
			print("Getting existing instance")
			return inst
		elif (!scene_data["use_fixed_size"]) or (scene_data["use_fixed_size"] and !preload_instances and scene_data["in_use"].size() < MAX_INSTANCES):
			var inst = scene_data["scene"].instantiate()
			inst.set_meta("cat_index", cat_index)
			inst.set_meta("index", index)
			inst.get_child(0).set_meta("color", Color.WHITE)
			scene_data["in_use"].append(inst)
			print("Getting new instance")
			return inst
		else:
			print("All instances in use and fixed-size is enabled for index:", index)
			return null
	else:
		print("Index out of bounds: ", index)
		return null

#return instance
func return_instance(instance: Node) -> void:
	var index: int = instance.get_meta("index")
	var cat_index: int = instance.get_meta("cat_index")
	
	if cat_index < pool.size() and index < pool[cat_index].size():
		var scene_data = pool[cat_index][index]
		if instance in scene_data["in_use"]:
			scene_data["in_use"].erase(instance)
			scene_data["instances"].append(instance)
			instance.visible = false
		else:
			print("Warning: instance not recognized as in-use.")
	else:
		print("Invalid category or index for returning instance.")

#unused
func get_size() -> int:
	return pool.size()

#clear the pool of all instances
func clear_all() -> void:
	for category in pool:
		for scene_data in category:
			scene_data["instances"].clear()
			scene_data["in_use"].clear()
	pool.clear()
