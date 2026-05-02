class_name MenuPanel extends Marker2D
@onready var title = %Title
@onready var offset = %Offset
@onready var artist = %Artist

var faded = false
enum 
{
	FADE_NONE,
	FADE_IN,
	FADE_OUT
}

func slide(newpoint,duration,fade = FADE_NONE,prev_tween:Tween = null):
	var tween:Tween
	if prev_tween !=null:
		tween = prev_tween
	else:
		tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self,'position',newpoint,duration)
	if fade != FADE_NONE:
		fade_animate(duration,fade)

func fade_animate(duration,fade):
	var tween:Tween = get_tree().create_tween()
	if fade == FADE_OUT:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(self,'modulate',Color.TRANSPARENT,duration)
		faded = true
	else:
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(self,'modulate',Color.WHITE,duration)
		faded = false

func fade_instant(fade):
	if fade == FADE_OUT:
		modulate = Color.TRANSPARENT
		faded = true
	else:
		modulate = Color.WHITE
		faded = false

func set_title(new_title:String):
	title.text = new_title

func set_artist(new_artist:String):
	artist.text = new_artist

func get_title()->String:
	return title.text

func get_artist()->String:
	return artist.text

func select_panel():
	QuickTweens.bounce(offset,"position:x",50)
