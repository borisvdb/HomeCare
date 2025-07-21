extends Window

func _on_focus_exited() -> void:
	hide()

func _on_next_page_button_down() -> void:
	if %Page_2.visible == false:
		%Page_1.hide()
		%Page_2.show()
		return
	
	%Page_1.show()
	%Page_2.hide()
