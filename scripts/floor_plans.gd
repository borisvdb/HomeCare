extends MeshInstance3D

var texture : ImageTexture

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
	
	adjust_plane_size(texture)

func adjust_plane_size(image: ImageTexture):
	var aspect_ratio = image.get_width() / float(image.get_height())
	var plane_size = Vector3(1, 1, 1)  # Default size of the plane

	# Adjust the size of the plane based on the aspect ratio
	if aspect_ratio > 1:
		plane_size.x *= aspect_ratio  # Wider
	else:
		plane_size.z /= aspect_ratio  # Taller

	self.scale = plane_size
