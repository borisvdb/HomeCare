extends Node3D

var object_id : int

@export var maintenance_threshold := 365 #days
@export var warranty_threshold := 32 #days

var building : Node3D
var contextual_menu : Window

@onready var outline : Node3D = %Outline
@onready var warranty_alert : Label3D
@onready var maintenance_alert : Label3D
@onready var maintenance_alert_urgent : Label3D

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if building.is_building:
		return
	
	if event.is_action_pressed("click"):
		contextual_menu.object_id = object_id
		contextual_menu.maintenance_threshold = maintenance_threshold
		contextual_menu.appliance_type = get_meta("Name")
		
		contextual_menu.position = event.position
		@warning_ignore("integer_division")
		contextual_menu.position.x -= contextual_menu.size.x/4
		contextual_menu.show()

func _on_area_3d_mouse_entered() -> void:
	if building.is_building:
		return
	outline.show()

func _on_area_3d_mouse_exited() -> void:
	if building.is_building:
		return
	outline.hide()

func _on_tree_entered() -> void:
	var k := 1000
	var o := 1000000
	
	var x_s := int(position.x * k) + o
	var y_s := int(position.y * k) + o
	var z_s := int(position.z * k) + o
	
	object_id = x_s * o + y_s * k + z_s
	
	building = get_tree().root.get_node("Main").get_node("Building")
	contextual_menu = get_tree().root.get_node("Main").get_node("Contextual_Menu")
	
	warranty_alert = %Warranty_Alert
	maintenance_alert = %Maintenance_Alert
	maintenance_alert_urgent = %Maintenance_Alert_Urgent
	
	connect_update_signals()
	
	set_maintenance_alert()
	set_warranty_alert()

func connect_update_signals() -> void:
	var warranty_info = get_tree().root.get_node("Main").get_node("Warranty_Info")
	var repair_history = get_tree().root.get_node("Main").get_node("Repair_History")
	warranty_info.updated_warranty_date.connect(set_warranty_alert)
	repair_history.updated_repair_date.connect(set_maintenance_alert)

func clear_all_rows() -> void:
	var sql_handler : SQLHandler = init_sql()
	sql_handler.delete_repair_object_id(object_id)
	sql_handler.delete_warranty_object_id(object_id)
	sql_handler.queue_free()

func _on_tree_exiting() -> void:
	building.is_saving.connect(clear_all_rows)

func set_maintenance_alert() -> void:
	var sql_handler : SQLHandler = init_sql()
	
	if sql_handler.is_nearly_lapsed(object_id, "repair_history", maintenance_threshold):
		maintenance_alert_urgent.hide()
		maintenance_alert.show()
	else:
		maintenance_alert_urgent.hide()
		maintenance_alert.hide()
	
	sql_handler.queue_free()
	sql_handler = init_sql()
	
	if sql_handler.is_nearly_lapsed(object_id, "repair_history", maintenance_threshold*4):
		maintenance_alert_urgent.show()
		maintenance_alert.hide()
	
	sql_handler.queue_free()

func set_warranty_alert() -> void:
	var sql_handler : SQLHandler = init_sql()
	
	if sql_handler.is_nearly_expired(object_id, "warranty_info", warranty_threshold):
		warranty_alert.show()
	else:
		warranty_alert.hide()

func init_sql() -> SQLHandler:
	var new_sql = SQLHandler.new()
	new_sql.initialize()
	new_sql.open_db()
	return new_sql
