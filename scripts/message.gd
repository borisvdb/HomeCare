extends CanvasLayer
class_name Message

@onready var message : Label = %Message_Label
@onready var anim : AnimationPlayer = %AnimationPlayer

func _ready() -> void:
	set_message("Welcome to HomeCare")

#Method for setting on screen message
func set_message(msg: String) -> void:
	if anim.is_playing():
		anim.stop()
	
	message.text += msg + "\n"
	anim.play("display_message")
	await anim.animation_finished
	message.text = ""
