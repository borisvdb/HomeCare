extends Window

var entry_list := preload("res://scenes/Entry_List.tscn")

var entry_list_inst : ItemList

@onready var animation_player : AnimationPlayer = %AnimationPlayer

@onready var stories_handler: Node = %StoriesHandler

@onready var input : TextEdit = %Input
@onready var day_input : SpinBox = %DD
@onready var month_input : SpinBox = %MM
@onready var year_input : SpinBox = %YYYY
@onready var hour_input : SpinBox = %HH
@onready var minute_input : SpinBox = %MIN

@onready var input_ins : TextEdit = %Input_Insert
@onready var day_input_ins : SpinBox = %DD_Insert
@onready var month_input_ins : SpinBox = %MM_Insert
@onready var year_input_ins : SpinBox = %YYYY_Insert
@onready var hour_input_ins : SpinBox = %HH_Insert
@onready var minute_input_ins : SpinBox = %MIN_Insert

@onready var input_window : Window = %Input_Window
@onready var input_window_date : Window = %Input_Window_Date
@onready var input_window_time : Window = %Input_Window_Time
@onready var input_window_insert_row : Window = %Input_Window_Insert_Row

@onready var cur_date_check : CheckBox = %Current_Date
@onready var cur_time_check : CheckBox = %Current_Time
@onready var cur_date_check_ins : CheckBox = %Current_Date_Insert
@onready var cur_time_check_ins : CheckBox = %Current_Time_Insert

@onready var confirm_delete : ConfirmationDialog = %ConfirmDelete

@onready var last_service_label : Label = %Last_Service_Label
@onready var maintenance_schedule_label : Label = %Maintenance_Schedule


var sql_handler : SQLHandler

const COLUMNS_AMOUNT : int = 5
var column_index : int
var selected_index : int
var id_index : int

var current_text : String = ""

var object_id : int = 12345
var maintenance_threshold := 365

signal updated_repair_date

func _ready() -> void:
	sql_handler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()

func set_time_since_last_service() -> void:
	var time_handler = SQLHandler.new()
	time_handler.initialize()
	time_handler.open_db()
	
	var lengths := time_handler.get_time_since_last_entry(object_id, "repair_history")
	var weeks : int = lengths[0]/7
	var days : int = lengths[0]%7
	var hours : int = lengths[1]
	last_service_label.text = "%d Weeks, %d Days, %d Hours Since Last Service" % [weeks, days, hours]
	
	time_handler.queue_free()

func populate_entry_list(order_column: String = "") -> void: #This has only been set up for repair data
	
	var this_child = get_child(0).get_child(0).get_child(1)
	
	if this_child.get_child_count() > 0:
		for child in this_child.get_children():
			child.queue_free()
	
	entry_list_inst = entry_list.instantiate()
	entry_list_inst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if order_column == "":
		order_column = "date"
	
	var results : Array = sql_handler.get_all_repair_data(object_id, order_column)
	
	for result in results:
		
		var n : int = entry_list_inst.item_count
		
		entry_list_inst.add_item(str(result["id"]))
		entry_list_inst.set_item_disabled(n, true)
		entry_list_inst.add_item(str(result["story"]))
		entry_list_inst.set_item_disabled(n+1, true)
		
		var date : Array = result["date"].split("-")
		var formatted_date : String
		if date.size() < 1:
			formatted_date = result["date"]
		else:
			formatted_date = "%s-%s-%s" % [ date[2], date[1], date[0] ]
		
		entry_list_inst.add_item(formatted_date)
		entry_list_inst.add_item(result["time"])
		entry_list_inst.add_item(result["comment"])
	
	entry_list_inst.item_selected.connect(_on_item_selected)
	entry_list_inst.item_activated.connect(_on_item_activated)
	
	this_child.add_child(entry_list_inst)
	
	set_maintenance_schedule()
	set_time_since_last_service()

func set_maintenance_schedule() -> void:
	maintenance_schedule_label.text = "Maintenance Schedule: %d Days" % maintenance_threshold

func _on_item_selected(index: int) -> void:
	selected_index = index
	column_index = selected_index % COLUMNS_AMOUNT
	@warning_ignore("integer_division")
	id_index = (index / COLUMNS_AMOUNT) * COLUMNS_AMOUNT
	
	print("selected_index ",selected_index)
	print("column_index ",column_index)
	print("id_index ",id_index)

func modify_data() -> void:
	
	var column_name : String = entry_list_inst.get_item_text(column_index)
	var id : String = entry_list_inst.get_item_text(id_index)
	
	match column_index:
		4, 3, 2: sql_handler.update_repair_data(id, column_name, current_text)

func _on_submit_button_down() -> void:
	current_text = input.text
	if current_text == "":
		animation_player.play("missing_comment")
		return
	
	input_window.hide()
	input.text = ""
	modify_data()
	populate_entry_list()

func _on_submit_date_button_down() -> void:
	input_window_date.hide()
	if !cur_date_check.button_pressed:
		current_text = str(int(year_input.value)).pad_zeros(2) + "-" + str(int(month_input.value)).pad_zeros(2) + "-" + str(int(day_input.value)).pad_zeros(2)
	else:
		current_text = "00-00-00"
	modify_data()
	populate_entry_list()
	
	cur_date_check.button_pressed = false
	year_input.value = 0
	month_input.value = 0
	day_input.value = 0
	
	updated_repair_date.emit()

func _on_submit_time_button_down() -> void:
	input_window_time.hide()
	if !cur_time_check.button_pressed:
		current_text = str(int(hour_input.value)).pad_zeros(2) + ":" + str(int(minute_input.value)).pad_zeros(2) + ":00"
	else:
		current_text = "00:00:00"
	modify_data()
	populate_entry_list()
	
	cur_time_check.button_pressed = false
	hour_input.value = 0
	minute_input.value = 0

func _on_close_requested() -> void:
	input_window.hide()
	input_window_date.hide()
	input_window_time.hide()
	input_window_insert_row.hide()
	hide()

func _on_input_window_close_requested() -> void:
	input_window.hide()

func _on_input_window_date_close_requested() -> void:
	input_window_date.hide()

func _on_input_window_insert_row_close_requested() -> void:
	input_window_insert_row.hide()

func _on_input_window_time_close_requested() -> void:
	input_window_time.hide()

func _on_item_activated(index: int) -> void:
	_on_item_selected(index)
	populate_entry_list(entry_list_inst.get_item_text(column_index))

func _on_update_column_button_down() -> void:
	if entry_list_inst.get_selected_items().size() < 1:
		return
	match column_index:
		4: input_window.show()
		3: input_window_time.show()
		2: input_window_date.show()

func _on_insert_row_button_down() -> void:
	input_window_insert_row.show()

func _on_delete_row_button_down() -> void:
	if entry_list_inst.get_selected_items().size() < 1:
		return
	confirm_delete.show()

func _on_confirm_delete_canceled() -> void:
	confirm_delete.hide()

func _on_confirm_delete_confirmed() -> void:
	sql_handler.delete_repair(int(entry_list_inst.get_item_text(id_index)))
	populate_entry_list()
	confirm_delete.hide()
	updated_repair_date.emit()

func _on_submit_insert_row_button_down() -> void:
	if input_ins.text == "":
		animation_player.play("missing_comment")
		return
	
	var date : String
	var time : String
	
	if !cur_date_check_ins.button_pressed:
		date = str(int(year_input_ins.value)).pad_zeros(2) + "-" + str(int(month_input_ins.value)).pad_zeros(2) + "-" + str(int(day_input_ins.value)).pad_zeros(2)
	else:
		date = "00-00-00"
	if !cur_time_check_ins.button_pressed:
		time = str(int(hour_input_ins.value)).pad_zeros(2) + ":" + str(int(minute_input_ins.value)).pad_zeros(2) + ":00"
	else:
		time = "00:00:00"
	
	sql_handler.insert_repair_data(object_id, stories_handler.current_story, input_ins.text, date, time)
	populate_entry_list()
	input_window_insert_row.hide()
	
	input_ins.text = ""
	cur_date_check_ins.button_pressed = false
	cur_time_check_ins.button_pressed = false
	year_input_ins.value = 0
	month_input_ins.value = 0
	day_input_ins.value = 0
	hour_input_ins.value = 0
	minute_input_ins.value = 0
	
	updated_repair_date.emit()
