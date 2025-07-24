extends CanvasLayer

@onready var floor_plans : MeshInstance3D = %FloorPlans
var file_dialog : FileDialog

@onready var camera : Camera3D = %Camera3D
@onready var camera_pivot : Node3D = %Camera_Pivot

@onready var building : Node3D = %Building
@onready var main : Node3D = get_tree().root.get_node("Main")

@onready var stories_handler: Node = %StoriesHandler

var tab_container: TabContainer
var window: Window

var tween: Tween

var current_angle : float
@onready var stored_angle : float = camera_pivot.rotation_degrees.y
@onready var stored_camera_x_rot : float = camera.rotation_degrees.x

var top_camera_x_rot := -90

var viewing_top := false
var tweening := false
var tween_time : float = 0.25

const ZOOM_INCREMENT := 3.0
const MAX_ZOOM := 30.0
const MIN_ZOOM := 0.25

var current_floor := 0
var category_index := 0

func _ready() -> void:
	current_angle = stored_angle
	print("stored_angle: ", stored_angle)
	
	if has_node("MarginContainer/HBoxContainer/TabContainer"):
		tab_container = $MarginContainer/HBoxContainer/TabContainer
	
	if has_node("Colour_Swatch_Window"):
		window = %Colour_Swatch_Window
	
	if has_node("FileDialog"):
		file_dialog = %FileDialog

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("zoom_in"):
		var new_size = camera.size - ZOOM_INCREMENT
		
		if new_size < MIN_ZOOM:
			print("Cant zoom in anymore.")
			new_size = MIN_ZOOM + ZOOM_INCREMENT
		
		tween = create_tween()
		tween.tween_property(camera, "size", new_size, tween_time/2)

	if event.is_action_pressed("zoom_out"):
		var new_size = camera.size + ZOOM_INCREMENT
		
		if new_size > MAX_ZOOM:
			print("Cant zoom out anymore.")
			new_size = MAX_ZOOM - ZOOM_INCREMENT
		
		tween = create_tween()
		tween.tween_property(camera, "size", new_size, tween_time/2)
	
	if event is InputEventMagnifyGesture:
		var pinch_scale = event.factor
		var new_size = camera.size / pinch_scale
		
		if new_size < MIN_ZOOM:
			print("Can't zoom in anymore.")
			new_size = MIN_ZOOM + ZOOM_INCREMENT
		elif new_size > MAX_ZOOM:
			print("Can't zoom out anymore.")
			new_size = MAX_ZOOM - ZOOM_INCREMENT
			
		tween = create_tween()
		tween.tween_property(camera, "size", new_size, tween_time / 2)

func _on_rotate_cw_button_down() -> void:
	if tweening:
		return
	tweening = true
	
	var new_angle : float 
	new_angle = camera_pivot.rotation_degrees.y - 90
	
	if viewing_top:
		
		if new_angle <= (90 * 5)*-1:
			camera_pivot.rotation_degrees.y = 0.0
			new_angle = -90
		
		current_angle = new_angle + stored_angle
	else:
		
		if new_angle <= stored_angle - (90 * 5):
			camera_pivot.rotation_degrees.y = stored_angle
			new_angle = stored_angle - 90
		
		current_angle = new_angle
	
	tween = create_tween()
	
	tween.tween_property(camera_pivot, "rotation_degrees:y", new_angle, tween_time)
	await tween.finished
		
	print("Camera pivot angle: ", new_angle)
	tweening = false

func _on_rotate_ccw_button_down() -> void:
	if tweening:
		return
	tweening = true
	
	var new_angle : float 
	new_angle = camera_pivot.rotation_degrees.y + 90
	
	if viewing_top:
		
		if new_angle >= 90 * 5:
			camera_pivot.rotation_degrees.y = 0.0
			new_angle = 90
		
		current_angle = new_angle + stored_angle
	else:
		
		if new_angle >= stored_angle + (90 * 5):
			camera_pivot.rotation_degrees.y = stored_angle
			new_angle = stored_angle + 90
		
		current_angle = new_angle
	
	tween = create_tween()
	
	tween.tween_property(camera_pivot, "rotation_degrees:y", new_angle, tween_time)
	await tween.finished
	
	print("Camera pivot angle: ", new_angle)
	tweening = false

func _on_top_view_toggled(toggled_on: bool) -> void:
	if tweening:
		return
	tween = create_tween()
	tweening = true
	
	if toggled_on:
		viewing_top = true
		tween.tween_property(camera_pivot, "rotation_degrees:y", current_angle - stored_angle, tween_time)
		tween.tween_property(camera, "rotation_degrees:x", top_camera_x_rot, tween_time)
		await tween.finished
	else:
		viewing_top = false
		tween.tween_property(camera_pivot, "rotation_degrees:y", current_angle, tween_time)
		tween.tween_property(camera, "rotation_degrees:x", stored_camera_x_rot, tween_time)
		await tween.finished
		
	tweening = false

func _on_xray_mode_toggled(toggled_on: bool) -> void:
	main.set_xray_mode(toggled_on)

func _on_building_mode_toggled(toggled_on: bool) -> void:
	main.set_building_mode(toggled_on)
	if !toggled_on or toggled_on:
		current_floor = stories_handler.set_story(stories_handler.max_stories)

func reset_story() -> void:
	current_floor = stories_handler.set_story(stories_handler.max_stories)

func _on_floor_up_button_down() -> void:
	current_floor = stories_handler.set_story(current_floor+1)

func _on_floor_down_button_down() -> void:
	current_floor = stories_handler.set_story(current_floor-1)

func hide_colour_swatches(is_hiding:bool) -> void:
	if is_hiding:
		%Colour_Swatches.hide()
	else:
		%Colour_Swatches.show()

#Window:

func _on_colour_swatches_button_up() -> void:
	window.populate_swatches()
	window.show()

func _on_window_close_requested() -> void:
	window.hide()

#BELOW IS BUILD METHODS

func _on_clear_button_down() -> void:
	building.clear_walls()
	building.clear_floors()
	building.clear_appliances()

func _on_undo_button_down() -> void:
	building.undo()

func _on_make_floors_button_down() -> void:
	building.check_if_floorable()

func _on_save_button_down() -> void:
	building.combine_meshes()

func _on_create_new_floor_button_down() -> void:
	current_floor = stories_handler.create_new_story()

#For dealing with floor plans

func _on_upload_floor_plans_button_down() -> void:
	file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	floor_plans.load_image(path)

func _on_floor_plans_button_down() -> void:
	if !%Floor_Plans_Popup.visible:
		%Floor_Plans_Popup.show()
	else:
		%Floor_Plans_Popup.hide()

func _on_increase_floor_plan_size_button_down() -> void:
	var incr := 0.005
	floor_plans.scale += Vector3(incr,incr,incr)

func _on_decrease_floor_plan_size_button_down() -> void:
	var incr := 0.005
	floor_plans.scale -= Vector3(incr,incr,incr)

#For selecting floors and walls

func _on_option_item_selected(index: int) -> void:
	building.set_wall_type(index)

func _on_tab_container_tab_changed(tab: int) -> void:
	building.set_category(tab)
	building.set_wall_type(0) #Make sure to reset wall selection so it doesnt go out of bounds
	for option_button : OptionButton in tab_container.get_children():
		option_button.select(0) #Reset the selected tab

func _on_paint_mode_toggled(toggled_on: bool) -> void:
	building.is_painting = toggled_on

func _on_color_picker_button_color_changed(color: Color) -> void:
	building.set_color(color)
