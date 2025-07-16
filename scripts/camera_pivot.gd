extends Node3D

@onready var camera : Camera3D = %Camera3D
var dragging := false
var pan_speed : float
var bounds : float = 30.0

func _ready() -> void:
	pan_speed = DisplayServer.window_get_size().x * 0.000001

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("pan_camera") or event is InputEventScreenDrag:
		if event is InputEventMouseMotion:
			pan_camera(event)
		elif event is InputEventScreenDrag and !%Building.is_building:
			pan_camera(event)
	else:
		dragging = false

func check_out_of_bounds() -> void:
	if position.x > bounds:
		position.x = bounds
	elif position.x < bounds*-1:
		position.x = bounds*-1
	
	if position.z > bounds:
		position.z = bounds
	elif position.z < bounds*-1:
		position.z = bounds*-1

func pan_camera(event: InputEvent) -> void:
	var cam_pan_speed : float = camera.size * pan_speed
	dragging = true
	var delta = event.relative
	translate(Vector3(-delta.x * cam_pan_speed, 0, -delta.y * (cam_pan_speed*1.35)))
	check_out_of_bounds()
