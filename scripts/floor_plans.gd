extends MeshInstance3D

var texture : ImageTexture
var aspect_ratio : float

var base_scale := 1.0
var plane_size := Vector3(1, 1, 1)

func load_image(file_path: String):
	var image_resource = load(file_path)
	
	if image_resource is ImageTexture:
		texture = image_resource
	else:
		var image = Image.new()
		var error = image.load(file_path)
		
		if error != OK:
			%Message.set_message("Error loading file!")
			return
			
		texture = ImageTexture.create_from_image(image)
	
	self.material_override.albedo_texture = texture
	self.material_override.transparency = false
	
	get_aspect_ratio(texture)

func get_aspect_ratio(image: ImageTexture):
	aspect_ratio = image.get_width() / float(image.get_height())
	adjust_plane_size()

func adjust_plane_size():
	var new_scale := plane_size * base_scale
	# Adjust the size of the plane based on the aspect ratio
	if aspect_ratio > 1:
		new_scale.x *= aspect_ratio  # Wider
	else:
		new_scale.z /= aspect_ratio  # Taller

	self.scale = new_scale
