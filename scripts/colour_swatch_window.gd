extends Window

@onready var swatch_list := preload("res://scenes/Swatch_List.tscn")
@onready var swatch_icon := preload("res://textures/swatch.tres")

@onready var confirm_delete : ConfirmationDialog = %ConfirmDelete

@onready var scroll_container_child = get_child(0)

func populate_swatches() -> void:
	if scroll_container_child.get_child(0).get_child_count() > 0: #Free the last container
		scroll_container_child.get_child(0).get_child(0).queue_free()
	
	var sql_handler : SQLHandler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()
	
	var swatch_list_inst : ItemList = swatch_list.instantiate()
	
	var results : Array = sql_handler.get_all_colour_swatch_data()
	
	var hex_dict := {}
	var i := 0
	
	for result in results:
		var c_name : String = result["name"]
		var story : int = result["story"]
		if hex_dict.has(c_name):
			var val : Array = hex_dict[c_name]
			val[0] += ", %d" % [story]
			hex_dict[c_name] = val
			swatch_list_inst.set_item_tooltip(val[1], val[0])
			continue
		var hex : String = result["hex"]
		hex_dict[c_name] = ["Name: %s\nHex: %s\nStorey: %d" % [c_name, hex, story], i]
		
		swatch_list_inst.add_item(c_name, swatch_icon)
		swatch_list_inst.set_item_icon_modulate(i, Color(hex))
		swatch_list_inst.set_item_tooltip(i, hex_dict[c_name][0])
		i+=1
	
	scroll_container_child.get_child(0).add_child(swatch_list_inst)
	
	sql_handler.close_db()
	sql_handler.queue_free()

func _on_confirm_delete_confirmed() -> void:
	var swatch_list_inst : ItemList = scroll_container_child.get_child(0).get_child(0)
	var selected_items := swatch_list_inst.get_selected_items()
	
	for selected_item in selected_items:
		var text := swatch_list_inst.get_item_text(selected_item)
		delete_swatch(text)
	
	populate_swatches()

func delete_swatch(c_name: String) -> void:
	var sql_handler : SQLHandler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()
	sql_handler.delete_col(c_name)
	sql_handler.close_db()
	sql_handler.queue_free()

func _on_delete_button_up() -> void:
	var swatch_list_inst : ItemList = scroll_container_child.get_child(0).get_child(0)
	if swatch_list_inst.get_selected_items().is_empty():
		return
	
	confirm_delete.show()
