extends Node

const FLOOR_HEIGHT := 2.55

var current_story := 0
var max_stories := 0

@onready var building : Node3D = %Building

@onready var wall_story_container: Node3D = %WallStoryContainer
@onready var floor_story_container: Node3D = %FloorStoryContainer
@onready var appliance_story_container: Node3D = %ApplianceStoryContainer

@onready var multimesh_story_container: Node3D = %MultiMeshStoryContainers
var mm_story_free_container : Node3D
var mm_wall_story_container : Node3D
var mm_floor_story_container : Node3D
var is_building : bool

@onready var ground_collision: StaticBody3D = %GroundCollision

@onready var message : Message = %Message

func create_new_story() -> int:
	var cur_story_wall_count := wall_story_container.get_child(max_stories).get_child_count()
	var cur_story_floor_count := floor_story_container.get_child(max_stories).get_child_count()
	
	if !cur_story_wall_count or !cur_story_floor_count:
		message.set_message("Please add walls and floors before creating a new level")
		return current_story
	
	max_stories += 1
	building.append_new_dict()
	
	set_story(max_stories)
	
	return current_story

func set_story(index : int) -> int:
	if index > max_stories:
		message.set_message("Max floor reached")
		return current_story
	elif index < 0:
		message.set_message("Ground floor reached")
		return current_story
	
	delete_top_story_if_empty()
	
	current_story = index
	ground_collision.position.y = FLOOR_HEIGHT * current_story
	
	hide_stories()
	
	return current_story

func hide_stories() -> void:
	if is_instance_valid(multimesh_story_container.get_child(0)) and !mm_story_free_container:
		mm_story_free_container = multimesh_story_container.get_child(0)
		mm_wall_story_container = mm_story_free_container.get_child(0)
		mm_floor_story_container = mm_story_free_container.get_child(1)
		
	if is_building:
	# Hide all stories above the current one
		for i in range(max_stories + 1):
			if i > current_story:
				if wall_story_container.get_child_count() > i:
					wall_story_container.get_child(i).hide()
				if floor_story_container.get_child_count() > i:
					floor_story_container.get_child(i).hide()
				if appliance_story_container.get_child_count() > i:
					appliance_story_container.get_child(i).hide()
			else:
				if wall_story_container.get_child_count() > i:
					wall_story_container.get_child(i).show()
				if floor_story_container.get_child_count() > i:
					floor_story_container.get_child(i).show()
				if appliance_story_container.get_child_count() > i:
					appliance_story_container.get_child(i).show()
	elif mm_wall_story_container:
		var mm_max_stories: int = mm_wall_story_container.get_child_count()
		# Hide all mm stories above the current one
		for i in range(mm_max_stories + 1):
			if i > current_story:
				if mm_wall_story_container.get_child_count() > i:
					mm_wall_story_container.get_child(i).hide()
				if mm_floor_story_container.get_child_count() > i:
					mm_floor_story_container.get_child(i).hide()
				if appliance_story_container.get_child_count() > i:
					appliance_story_container.get_child(i).hide()
			else:
				if mm_wall_story_container.get_child_count() > i:
					mm_wall_story_container.get_child(i).show()
				if mm_floor_story_container.get_child_count() > i:
					mm_floor_story_container.get_child(i).show()
				if appliance_story_container.get_child_count() > i:
					appliance_story_container.get_child(i).show()

func _on_building_is_building_changed(new_value: bool) -> void:
	is_building = new_value

func delete_top_story_if_empty() -> void:
	
	if current_story == max_stories -1 or current_story == 0:
		return
	
	var top_story_wall_count := wall_story_container.get_child(max_stories).get_child_count()
	var top_story_floor_count := floor_story_container.get_child(max_stories).get_child_count()
	
	if top_story_wall_count == 0 and top_story_floor_count == 0:
		wall_story_container.remove_child(wall_story_container.get_child(max_stories))
		floor_story_container.remove_child(floor_story_container.get_child(max_stories))
		
		# Decrease the max_stories count
		max_stories -= 1
		
		#message.set_message("Top story deleted as it was empty.")
