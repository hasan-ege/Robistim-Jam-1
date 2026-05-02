extends Control

## Animated Level Select Screen with looping carousel selection.
## The middle icon is highlighted and larger than the others.

signal level_selected

@export var level_paths : Array[String] = [
	"res://levels/level1.tscn",
	"res://levels/level2.tscn",
	"res://levels/level3.tscn"
]

@export var level_names : Array[String] = [
	"Raspberry Jam",
	"Techno Beat",
	"Final Rhythm"
]

@export var level_music_paths : Array[String] = [
	"res://assets/raspberry_jam.ogg",
	"res://assets/raspberry_jam.ogg",
	"res://assets/raspberry_jam.ogg"
]

@export var card_size : Vector2 = Vector2(280, 280)
@export var card_spacing : float = 320.0
@export var animation_duration : float = 0.4
@export var scale_highlight : float = 1.3

@onready var cards_container = %CardsContainer
@onready var level_name_label = %LevelNameLabel
@onready var left_button = %LeftButton
@onready var right_button = %RightButton

var current_index : int = 0
var cards : Array[Control] = []
var is_transitioning : bool = false

func _ready() -> void:
	# Ensure the game is not paused when returning to level select
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Initial preview
	_update_preview()
	# Clean up any editor placeholders
	for child in cards_container.get_children():
		child.queue_free()
	
	# Create cards for each level
	for i in range(level_paths.size()):
		var card = _create_card(i)
		cards_container.add_child(card)
		cards.append(card)
		
		# Connect click signal if needed, but we mainly use focus/keyboard
		card.gui_input.connect(_on_card_gui_input.bind(i))
	
	# Initial layout
	await get_tree().process_frame
	update_selection(true)
	
	# Connect buttons
	left_button.pressed.connect(rotate_selection.bind(-1))
	right_button.pressed.connect(rotate_selection.bind(1))

func _create_card(index: int) -> Control:
	var card = Control.new()
	card.custom_minimum_size = card_size
	card.size = card_size
	card.pivot_offset = card_size / 2.0
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Background/Border
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# We'll use a StyleBoxFlat for a nice rounded look
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(1, 1, 1, 0.5)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	panel.add_theme_stylebox_override("panel", style)
	card.add_child(panel)
	
	# Icon Placeholder
	var texture_rect = TextureRect.new()
	texture_rect.name = "Icon"
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_rect.offset_left = 10
	texture_rect.offset_top = 10
	texture_rect.offset_right = -10
	texture_rect.offset_bottom = -10
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# The user will set these textures themselves
	panel.add_child(texture_rect)
	
	return card

func _on_card_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if index == current_index:
			select_level()
		else:
			# Calculate direction
			var diff = index - current_index
			if diff > level_paths.size() / 2.0: diff -= level_paths.size()
			if diff < -level_paths.size() / 2.0: diff += level_paths.size()
			rotate_selection(sign(diff))

func _input(event: InputEvent) -> void:
	if not visible or is_transitioning: return
	
	if event.is_action_pressed("ui_left"):
		rotate_selection(-1)
	elif event.is_action_pressed("ui_right"):
		rotate_selection(1)
	elif event.is_action_pressed("ui_accept"):
		select_level()

func rotate_selection(direction: int) -> void:
	if is_transitioning: return
	
	current_index = (current_index + direction + level_paths.size()) % level_paths.size()
	update_selection()

func update_selection(immediate: bool = false) -> void:
	is_transitioning = true
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	level_name_label.text = level_names[current_index]
	
	# Staggered appearance for name label
	if not immediate:
		level_name_label.modulate.a = 0
		var text_tween = create_tween()
		text_tween.tween_property(level_name_label, "modulate:a", 1.0, 0.2)
		_update_preview()
	
	for i in range(cards.size()):
		var card = cards[i]
		# Calculate relative index to center
		var diff = i - current_index
		
		# Handle looping distance for display logic
		var loop_size = level_paths.size()
		if diff > loop_size / 2.0:
			diff -= loop_size
		elif diff < -loop_size / 2.0:
			diff += loop_size
			
		var target_pos_x = diff * card_spacing - card.size.x / 2.0
		var target_pos_y = -card.size.y / 2.0
		var target_scale = 1.0
		var target_alpha = 0.7
		var target_z = 0
		
		if diff == 0:
			target_scale = scale_highlight
			target_alpha = 1.0
			target_z = 10
		elif abs(diff) > 1:
			# Hide items that are too far in a 3-item loop
			target_alpha = 0.0
		
		if immediate:
			card.position = Vector2(target_pos_x, target_pos_y)
			card.scale = Vector2(target_scale, target_scale)
			card.modulate.a = target_alpha
			card.z_index = target_z
		else:
			tween.tween_property(card, "position", Vector2(target_pos_x, target_pos_y), animation_duration)
			tween.tween_property(card, "scale", Vector2(target_scale, target_scale), animation_duration)
			tween.tween_property(card, "modulate:a", target_alpha, animation_duration)
			card.z_index = target_z
			
	if not immediate:
		await tween.finished
	
	is_transitioning = false

func select_level() -> void:
	if is_transitioning: return
	
	# Visual feedback for selection
	var card = cards[current_index]
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(scale_highlight + 0.2, scale_highlight + 0.2), 0.1)
	tween.tween_property(card, "scale", Vector2(scale_highlight, scale_highlight), 0.1)
	
	await tween.finished
	
	GameState.set_checkpoint_level_path(level_paths[current_index])
	if get_signal_connection_list("level_selected").is_empty():
		SceneLoader.load_scene(level_paths[current_index])
	else:
		level_selected.emit()

func _update_preview() -> void:
	if current_index >= 0 and current_index < level_music_paths.size():
		var music_path = level_music_paths[current_index]
		var stream = load(music_path)
		if stream:
			ProjectMusicController.play_stream(stream, 30.0, -10.0)

func _on_back_button_pressed() -> void:
	# Resume menu music
	var menu_music = load("res://Music/contemplation.ogg")
	ProjectMusicController.play_stream(menu_music, 0.0, 0.0)
	
	if get_parent().has_method("_close_sub_menu"):
		get_parent()._close_sub_menu()
	else:
		SceneLoader.load_scene("res://ui/menus/main_menu/animated_main_menu.tscn")
