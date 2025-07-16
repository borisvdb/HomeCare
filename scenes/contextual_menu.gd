extends Window

@onready var repair_history : Window = %Repair_History
@onready var warranty_info : Window = %Warranty_Info
var object_id : int
var appliance_type : String
var maintenance_threshold := 365 #days

func _on_focus_exited() -> void:
	hide()

func _on_repair_history_button_down() -> void:
	repair_history.object_id = object_id
	repair_history.maintenance_threshold = maintenance_threshold
	repair_history.title = appliance_type + " Repair History"
	repair_history.populate_entry_list()
	repair_history.show()

func _on_warranty_info_button_down() -> void:
	warranty_info.object_id = object_id
	warranty_info.title = appliance_type + " Warranty Info"
	warranty_info.populate_info()
	warranty_info.show()
