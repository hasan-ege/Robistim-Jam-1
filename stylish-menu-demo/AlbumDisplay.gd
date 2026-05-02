extends PanelContainer
@onready var album_text:TextureRect = %AlbumText
@onready var hidden_image:TextureRect = %HiddenImage
@export var slidedistance:float = 40.0
@export var time:float = .5
var current_tween:Tween = null
func display(newtexture:Texture2D):
	album_text.texture = newtexture

func _on_cycling_menu_option_changed(sample:Song_Sample, direction:int=0):
	hidden_image.visible = true
	hidden_image.position = Vector2.ZERO
	hidden_image.modulate = Color.WHITE
	if current_tween != null:
		hidden_image.texture = album_text.texture
		current_tween.kill()
	current_tween = get_tree().create_tween()
	current_tween.set_ease(Tween.EASE_OUT)
	current_tween.set_trans(Tween.TRANS_CIRC)
	current_tween.tween_property(hidden_image,'position:y',slidedistance*direction,time)
	current_tween.parallel().tween_property(hidden_image,'modulate',Color.TRANSPARENT,time)
	current_tween.tween_callback(func():
		hidden_image.visible = false
		hidden_image.texture = sample.Album)
	display(sample.Album)
	pass # Replace with function body.


func _on_cycling_menu_start(sample:Song_Sample):
	display(sample.Album)
	hidden_image.texture = sample.Album
	
	pass # Replace with function body.
