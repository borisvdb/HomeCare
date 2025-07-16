extends PanelContainer

var this_id : int
var this_hex : String
var this_story : int

var queued_for_deletion := false

func _initialize(id: int, hex : String, story: int, c_name: String,) -> void:
	%Label_Hex.text = hex
	%Label_Story.text = str(story)
	%Label_Name.text = c_name
	%Swatch.modulate = Color(hex)
	
	this_id = id
	this_hex = hex
	this_story = story

func show_delete_button(is_show) -> void:
	if is_show:
		%Delete.show()
	else:
		%Delete.hide()

func delete_swatch() -> void:
	var sql_handler : SQLHandler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()
	sql_handler.delete_col(this_id)
	sql_handler.close_db()
	queue_free()

func _on_delete_toggled(toggled_on: bool) -> void:
	queued_for_deletion = toggled_on
