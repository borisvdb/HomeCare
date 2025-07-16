extends Node

var config: ConfigFile = ConfigFile.new()
const SETTINGS_FILE_PATH = "user://save_data/settings.ini"

func _ready():
	if !FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.set_value("loading", "max_stories", 0)
		config.set_value("loading", "first_time", 1)
		config.save(SETTINGS_FILE_PATH)
	else:
		config.load(SETTINGS_FILE_PATH)

func save_loading_settings(key: String, value):
	config.set_value("loading", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_loading_settings(key: String):
	return config.get_value("loading", key)
