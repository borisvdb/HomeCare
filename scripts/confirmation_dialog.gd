extends ConfirmationDialog

func _on_confirmed() -> void:
	get_tree().quit()

func _on_canceled() -> void:
	hide()
