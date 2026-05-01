extends MainMenu
## Main menu extension simplified for Level System.

## Optional scene to open when the player clicks a 'Play' button (Level Select).
@export var level_select_packed_scene: PackedScene

@onready var play_button = %NewGameButton
@onready var level_select_button = %LevelSelectButton

func _ready() -> void:
	super._ready()
	# In a level system, we might want the Play button to go directly to Level Select
	# or just start the first level if no levels are reached.
	play_button.text = "PLAY"
	
	# Hide unnecessary things
	if get_node_or_null("%ContinueGameButton"):
		%ContinueGameButton.visible = false
	if get_node_or_null("%CreditsButton"):
		%CreditsButton.visible = false

func new_game() -> void:
	# Rename functionality: Play button now opens level select or starts game
	if level_select_packed_scene:
		_on_level_select_button_pressed()
	else:
		GameState.reset()
		load_game_scene()

func load_game_scene() -> void:
	var path = GameState.get_checkpoint_level_path()
	if path.is_empty():
		path = "res://levels/level1.tscn"
	SceneLoader.load_scene(path)

func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)


