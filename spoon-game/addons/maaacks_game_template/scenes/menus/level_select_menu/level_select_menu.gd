extends Control

## Loads a simple ItemList node within a margin container. SceneLister updates
## the available scenes in the directory provided. Activating a level will update
## the GameState's current_level, and emit a signal. The main menu node will trigger
## a load action from that signal.

signal level_selected

@onready var level_buttons_container: ItemList = %LevelButtonsContainer
@onready var scene_lister: SceneLister = $SceneLister
var level_paths : Array[String]

func _ready() -> void:
	add_levels_to_container()
	
## A fresh level list is propgated into the ItemList, and the file names are cleaned
func add_levels_to_container() -> void:
	level_buttons_container.clear()
	level_paths.clear()
	
	# Use the SceneLister's files if available, otherwise fallback to GameState
	var levels_to_show : Array[String] = []
	if scene_lister and not scene_lister.files.is_empty():
		levels_to_show = scene_lister.files
	else:
		# Fallback to keys if any exist
		for k in GameState.get_or_create_state().level_states.keys():
			levels_to_show.append(k)
	
	for file_path in levels_to_show:
		var file_name : String = file_path.get_file()
		file_name = file_name.trim_suffix(".tscn")
		file_name = file_name.replace("_", " ")
		file_name = file_name.capitalize()
		level_buttons_container.add_item(file_name)
		level_paths.append(file_path)


func _on_level_buttons_container_item_activated(index: int) -> void:
	GameState.set_checkpoint_level_path(level_paths[index])
	level_selected.emit()
