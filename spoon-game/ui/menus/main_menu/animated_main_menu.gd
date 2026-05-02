extends MainMenu

## Custom main menu with staggered entry animations and focus-based selection animations.

@export var slide_offset : float = 400.0
@export var slide_duration : float = 0.6
@export var stagger_delay : float = 0.1
@export var focus_slide_distance : float = 50.0

@export var level_select_packed_scene : PackedScene

@onready var continue_game_button = %ContinueGameButton
@onready var level_select_button = %LevelSelectButton
@onready var new_game_confirmation = %NewGameConfirmation

var buttons : Array[Button] = []
var base_x_positions : Dictionary = {}

func _ready() -> void:
	# Setup GameState logic
	_show_continue_if_set()
	_show_level_select_if_set()
	
	# Play main menu music
	var menu_music = load("res://Music/contemplation.ogg")
	ProjectMusicController.play_stream(menu_music)
	
	super._ready()
	
	# Collect all visible buttons in the container
	for child in menu_buttons_box_container.get_children():
		if child is Button and child.visible:
			buttons.append(child)
	
	# Setup initial state
	for button in buttons:
		button.modulate.a = 0
		# We use a small delay to let the container finish its first layout pass
		button.resized.connect(_on_button_resized.bind(button))
		
		# Connect signals for selection animations
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.focus_exited.connect(_on_button_focus_exited.bind(button))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	
	# Start entry animation after a short frame delay to ensure layout is ready
	await get_tree().process_frame
	animate_entry()
	
	# Focus the Level Select button by default
	level_select_button.grab_focus()

func _on_button_resized(button: Button) -> void:
	base_x_positions[button] = button.position.x

func animate_entry() -> void:
	var delay = 0.0
	for button in buttons:
		# Set initial off-screen position
		button.position.x -= slide_offset
		
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "position:x", button.position.x + slide_offset, slide_duration).set_delay(delay)
		tween.tween_property(button, "modulate:a", 1.0, slide_duration).set_delay(delay)
		delay += stagger_delay

func _on_button_focus_entered(button: Button) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# We use focus_slide_distance relative to its natural position
	var target_x = base_x_positions.get(button, 0.0) + focus_slide_distance
	tween.tween_property(button, "position:x", target_x, 0.2)
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	button.z_index = 1

func _on_button_focus_exited(button: Button) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target_x = base_x_positions.get(button, 0.0)
	tween.tween_property(button, "position:x", target_x, 0.2)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	button.z_index = 0

func _on_button_mouse_entered(button: Button) -> void:
	button.grab_focus()

func _show_level_select_if_set() -> void: 
	if level_select_packed_scene == null: return
	level_select_button.show()

func _show_continue_if_set() -> void:
	if GameState.get_current_level_path().is_empty(): return
	continue_game_button.show()

# Overriding MainMenu methods to include GameState logic
func load_game_scene() -> void:
	GameState.start_game()
	super.load_game_scene()

func new_game() -> void:
	# If there's a continue button visible, we might want to confirm
	if continue_game_button and continue_game_button.visible:
		new_game_confirmation.show()
	else:
		GameState.reset()
		load_game_scene()

func _on_continue_game_button_pressed() -> void:
	GameState.continue_game()
	load_game_scene()

func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)

func _on_new_game_confirmation_confirmed() -> void:
	GameState.reset()
	load_game_scene()
