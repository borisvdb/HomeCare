extends Node
class_name SQLHandler

var db : SQLite
const DB_PATH := "user://save_data/data.db"

func create_database() -> void:
	initialize()
	
	db.open_db()
	create_repair_history_table()
	create_colour_swatch_table()
	create_warranty_info_table()
	db.close_db()

func initialize() -> void:
	db = SQLite.new()
	db.path = DB_PATH

func open_db() -> void:
	db.open_db()

func close_db() -> void:
	db.close_db()

func create_repair_history_table() -> void:
	
	var table := {
		"id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"object_id" : {"data_type":"int", "not_null": true},
		"story" : {"data_type":"int", "not_null": true},
		"date" : {"data_type":"text", "not_null": true},
		"time" : {"data_type":"text", "not_null": true},
		"comment" : {"data_type":"text", "not_null": true}
	}
	
	db.create_table("repair_history", table)

func create_colour_swatch_table() -> void:
	
	var table := {
		"id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": true},
		"hex" : {"data_type":"text", "not_null": true},
		"story" : {"data_type":"int", "not_null": true},
		"name" : {"data_type":"text", "not_null": false}
	}
	
	db.create_table("colour_swatches", table)

func create_warranty_info_table() -> void:
	
	var table := {
		"object_id" : {"data_type":"int", "primary_key": true, "not_null": true, "auto_increment": false},
		"appliance_type" : {"data_type":"text", "not_null": true},
		"owner_name" : {"data_type":"text", "not_null": true},
		"purchase_date" : {"data_type":"text", "not_null": true},
		"expiry_date" : {"data_type":"text", "not_null": true},
		"serial_no" : {"data_type":"text", "not_null": true},
		"brand" : {"data_type":"text", "not_null": true},
		"link" : {"data_type":"text", "not_null": true},
	}
	
	db.create_table("warranty_info", table)

func has_col(hex : String, story : int) -> bool:
	db.query_with_bindings("SELECT *
							FROM colour_swatches
							WHERE hex = '"+hex+"' 
							AND story = ?;", [story])
	
	return !db.query_result.is_empty()

func get_hex_as_arr(story: int) -> Array:
	
	db.query_with_bindings("SELECT hex 
							FROM colour_swatches 
							WHERE story = ?;", [story])
	
	return db.query_result

func get_all_colour_swatch_data() -> Array:
	db.query("SELECT * 
			FROM colour_swatches
			ORDER BY story;")
	
	return db.query_result
#cccac8
func get_all_repair_data(object_id: int, order_column: String) -> Array:
	db.query_with_bindings("SELECT * 
							FROM repair_history 
							WHERE object_id = ? 
							ORDER BY "+order_column+";", [object_id])
	
	return db.query_result

func get_all_warranty_data(object_id: int) -> Array:
	db.query_with_bindings("SELECT * 
							FROM warranty_info 
							WHERE object_id = ?;", [object_id])
	
	return db.query_result

func delete_col(c_name : String) -> void:
	db.query_with_bindings("DELETE 
							FROM colour_swatches
							WHERE name = ?;", [c_name])

func delete_repair(id : int) -> void:
	db.query_with_bindings("DELETE 
							FROM repair_history 
							WHERE id = ?;", [id])

func delete_repair_object_id(object_id: int) -> void:
	db.query_with_bindings("DELETE 
							FROM repair_history 
							WHERE object_id = ?;", [object_id])

func delete_warranty_object_id(object_id: int) -> void:
	db.query_with_bindings("DELETE 
							FROM warranty_info 
							WHERE object_id = ?;", [object_id])

func insert_colour_data(hex: String, story: int) -> void:
	var ntc : NTC = NTC.new()
	ntc._initialize()
	var c_name : String = ntc.ntc(hex)
	
	var data := {
		"hex" : hex,
		"story" : story,
		"name" : c_name
	}
	
	db.insert_row("colour_swatches", data)

func insert_repair_data(object_id: int, story: int, comment: String, date: String = "", time: String = "") -> void:
	if time == "00:00:00" or time == "":
		time = Time.get_time_string_from_system()
		
	if date == "00-00-00" or date == "":
		date = Time.get_date_string_from_system()
	
	var data := {
			"object_id" : object_id,
			"story" : story,
			"date" : date,
			"time" : time,
			"comment" : comment
		}
	
	db.insert_row("repair_history", data)

func insert_or_update_warranty_data(object_id: int, appliance_type: String, owner_name: String, purchase_date: String,
	expiry_date: String, serial_no: String, brand: String, link: String) -> void:
	db.query_with_bindings("INSERT OR REPLACE 
							INTO warranty_info (object_id, appliance_type, owner_name, purchase_date, 
							expiry_date, serial_no, brand, link)
							VALUES (?, ?, ?, ?, ?, ?, ?, ?);", [object_id, appliance_type, owner_name, purchase_date, 
																expiry_date, serial_no, brand, link])

func update_repair_data(id: String, column_name : String, new_value : String) -> void:
	if column_name.to_lower() == "date" and new_value == "00-00-00":
		new_value = Time.get_date_string_from_system()
	elif column_name.to_lower() == "time" and new_value == "00:00:00":
		new_value = Time.get_time_string_from_system()
	
	db.query_with_bindings("UPDATE repair_history
							SET "+column_name+" = ?
							WHERE id = ?;", [new_value, id])

func get_datetime_dict(date_string : String, time_string: String) -> Dictionary:
	var time_parts = time_string.split(":")
	var hours = int(time_parts[0])
	var minutes = int(time_parts[1])
	var seconds = int(time_parts[2])
	
	var date_parts = date_string.split("-")
	var year = int(date_parts[0])
	var month = int(date_parts[1])
	var day = int(date_parts[2])
	
	var datetime_dict = {
		"year": year,
		"month": month,
		"day": day,
		"hours": hours,
		"minutes": minutes,
		"seconds": seconds
	}
	
	return datetime_dict

func get_time_since_last_entry(object_id: int, table : String) -> Array:
	
	db.query_with_bindings("SELECT date, time
							FROM "+table+"
							WHERE object_id = ?
							ORDER BY date DESC, time DESC
							LIMIT 1;", [object_id])
	
	if db.query_result.is_empty():
		return [0, 0, 0]
	
	var last_datetime = get_datetime_dict(db.query_result[0]["date"], db.query_result[0]["time"])
	db.close_db()
	
	var now_datetime := Time.get_datetime_dict_from_system()
	
	var last_unix_time := Time.get_unix_time_from_datetime_dict(last_datetime)
	var now_unix_time := Time.get_unix_time_from_datetime_dict(now_datetime)
	
	var diff_seconds = now_unix_time - last_unix_time
	
	@warning_ignore("integer_division")
	var diff_days := int(diff_seconds / 86400)
	@warning_ignore("integer_division")
	var diff_hours := int((diff_seconds % 86400) / 3600)
	@warning_ignore("integer_division")
	var diff_minutes := int((diff_seconds % 3600) / 60)
	
	return [diff_days, diff_hours, diff_minutes]

func get_time_remaining_till_date(object_id: int, table : String) -> Array:
	
	db.query_with_bindings("SELECT expiry_date
							FROM "+table+"
							WHERE object_id = ?;", [object_id])
	
	if db.query_result.is_empty():
		return [00,00]
	
	var expiry_datetime := get_datetime_dict(db.query_result[0]["expiry_date"], "00:00:00")
	db.close_db()
	
	var now_datetime := Time.get_datetime_dict_from_system()
	
	var expiry_unix_time := Time.get_unix_time_from_datetime_dict(expiry_datetime)
	var now_unix_time := Time.get_unix_time_from_datetime_dict(now_datetime)
	
	var diff_seconds := expiry_unix_time - now_unix_time
	
	if diff_seconds <= 0:
		return [00,00]
	
	@warning_ignore("integer_division")
	var diff_days := int(diff_seconds / 86400)
	@warning_ignore("integer_division")
	var diff_hours := int((diff_seconds % 86400) / 3600)
	
	return [diff_days, diff_hours]

func is_nearly_expired(object_id: int, table : String, days : int) -> bool:
	var lengths := get_time_remaining_till_date(object_id, table)
	if lengths == [00,00]:
		return false
	
	if lengths[0] < days:
		return true
	
	return false

func is_nearly_lapsed(object_id: int, table : String, days : int) -> bool:
	var lengths := get_time_since_last_entry(object_id, table)
	
	if lengths[0] > days:
		return true
	
	return false
