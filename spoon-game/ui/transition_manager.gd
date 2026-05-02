extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _process(delta: float) -> void:
	if color_rect and color_rect.material:
		color_rect.material.set_shader_parameter("node_resolution", get_viewport().get_visible_rect().size)

func transition_to(scene_path: String) -> void:
	color_rect.visible = true
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	get_tree().change_scene_to_file(scene_path)
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	color_rect.visible = false
