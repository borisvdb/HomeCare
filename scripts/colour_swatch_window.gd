extends Window

@onready var swatch := preload("res://scenes/Colour_Swatch.tscn")
@onready var sw_gridcontainer := preload("res://scenes/Swatch_Grid_Container.tscn")

@onready var confirm_delete : ConfirmationDialog = %ConfirmDelete
var swatches := []

@onready var scroll_container_child = get_child(0)

func populate_swatches() -> void:
	if scroll_container_child.get_child(0).get_child_count() > 0: #Free the last container
		get_child(0).get_child(0).get_child(0).queue_free()
	
	var sql_handler : SQLHandler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()
	
	var container : GridContainer = GridContainer.new()
	container.columns = 4
	
	var results : Array = sql_handler.get_all_colour_swatch_data()
	
	for result in results:
		var swatch_inst := swatch.instantiate()
		var hex : String = result["hex"]
		var c_name : String = result["name"]
		var id : int = result["id"]
		
		swatch_inst._initialize(id, hex, result["story"], c_name,)
		container.add_child(swatch_inst)
	
	scroll_container_child.get_child(0).add_child(container)
	
	sql_handler.close_db()
	sql_handler.queue_free()

func _on_refresh_button_button_down() -> void:
	%Start_Deleting.button_pressed = false
	populate_swatches()

func _on_start_deleting_button_down() -> void:
	if scroll_container_child.get_child(0).get_child_count() == 0:
		return
	
	var container = scroll_container_child.get_child(0).get_child(0)
	
	for col_swatch in container.get_children():
		if col_swatch.queued_for_deletion:
			swatches.append(col_swatch)
	
	if swatches.is_empty():
		return
	
	confirm_delete.show()

func _on_confirm_delete_confirmed() -> void:
	for col_swatch in swatches:
		col_swatch.delete_swatch()
	
	swatches.clear()
