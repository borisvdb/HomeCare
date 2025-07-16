extends Window

@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var warranty_expiry_label : Label = %Warranty_Expiry_Label

var message := "Warranty Expires in %d Weeks, %d Days, %d Hours"
var starting_message := "Click the Button in the Lower Right Corner to Create a New Warranty Card"

var object_id : int = 12345

var sql_handler : SQLHandler

signal updated_warranty_date

@onready var inputs := [
				%Appliance_Type_Input,
				%Owner_Name_Input,
				%Purchase_Date_Input,
				%Expiration_Date_Input,
				%Serial_No_Input,
				%Brand_Name_Input,
				%Website_Link_Input,
				%Save
				]

@onready var label_results := [
				%Appliance_Type_Result,
				%Owner_Name_Result,
				%Purchase_Date_Result,
				%Expiration_Date_Result,
				%Serial_No_Result,
				%Brand_Name_Result,
				%Website_Link_Result,
				]

func _ready() -> void:
	sql_handler = SQLHandler.new()
	sql_handler.initialize()
	sql_handler.open_db()

func _on_edit_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		for input in inputs:
			input.show()
		for result in label_results:
			result.hide()
	else:
		for input in inputs:
			input.hide()
		for result in label_results:
			result.show()

func _on_save_button_down() -> void:
	for input in inputs:
		if input is TextEdit and input.text == "":
			animation_player.play("missing_info")
			return
	
	var purchase_date_str : String = "%d-%d-%d" % [inputs[2].get_child(2).value, inputs[2].get_child(1).value, inputs[2].get_child(0).value]
	var expiry_date_str : String = "%d-%d-%d" % [inputs[3].get_child(2).value, inputs[3].get_child(1).value, inputs[3].get_child(0).value]
	
	if Time.get_unix_time_from_datetime_string(purchase_date_str) >= Time.get_unix_time_from_datetime_string(expiry_date_str):
		animation_player.play("missing_info")
		return
	
	_on_edit_button_toggled(false)
	
	sql_handler.insert_or_update_warranty_data(object_id, inputs[0].text, inputs[1].text, purchase_date_str, expiry_date_str, inputs[4].text, inputs[5].text, inputs[6].text)
	populate_info()
	updated_warranty_date.emit()

func populate_info() -> void:
	
	var results : Array = sql_handler.get_all_warranty_data(object_id)
	
	if results.is_empty():
		for label_result in label_results:
			label_result.text = "Undefined"
		warranty_expiry_label.text = starting_message
		return
	
	var column_names := ["appliance_type", 
						"owner_name", 
						"purchase_date",
						"expiry_date",
						"serial_no",
						"brand",
						"link"]
	
	var p_date : Array = results[0]["purchase_date"].split("-")
	results[0]["purchase_date"]  = "%s-%s-%s" % [ p_date[2], p_date[1], p_date[0] ]
	var e_date : Array = results[0]["expiry_date"].split("-")
	results[0]["expiry_date"]  = "%s-%s-%s" % [ e_date[2], e_date[1], e_date[0] ]
	
	for i in range(label_results.size()):
		label_results[i].text = results[0][column_names[i]]
		if inputs[i] is TextEdit:
			inputs[i].text = results[0][column_names[i]]
		if label_results[i] is LinkButton:
			label_results[i].uri = results[0][column_names[i]]
		
	set_time_remaining_till_date()

func set_time_remaining_till_date() -> void:
	var time_handler = SQLHandler.new()
	time_handler.initialize()
	time_handler.open_db()
	
	var lengths := time_handler.get_time_remaining_till_date(object_id, "warranty_info")
	var weeks : int = lengths[0]/7
	var days : int = lengths[0]%7
	var hours : int = lengths[1]
	warranty_expiry_label.text = message % [weeks, days, hours]
	
	time_handler.queue_free()

func _on_close_requested() -> void:
	_on_edit_button_toggled(false)
	hide()
