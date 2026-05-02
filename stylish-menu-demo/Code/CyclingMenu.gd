class_name CyclingMenu extends Marker2D

signal selected_option(selected)
signal option_changed(selected,direction)
signal start(selected)

@export var starting_panel:= 0
@export var panels := 5
@export var slide_duration := .5
@export var panel_scene: PackedScene
@export var content_array:Array[Song_Sample]
@onready var menu_pool = %menu_pool
@onready var seperation_value = %SeperationValue
@onready var height_value = %HeightValue
@onready var hidden_position = %Hiddenposition
@onready var shift_sound = $Shift_Sound
@onready var up = %UP
@onready var select = %SELECT
@onready var down = %DOWN

var range_offset = 0
var selector_panel:int

#var content_array = ["thing one","thing two","thing three","thing four","thing five","thing six","thing seven","thing eight","thing nine","thing ten"]
# panel offset was just a thought experiment on whether it was worth it to move the panels around in the scene
# tree or if it'd be better to have in-code offset.
#var panel_offset = 0
func _ready():
	#check for even or odd
	#odd panels
	if panels % 2 == 1:
		selector_panel = (panels - 1)/2
	#even panels
	else:
		selector_panel = panels/2
	for i in panels:
		print(i)
		var panel = panel_scene.instantiate()
		menu_pool.add_child(panel)
	var child_array = menu_pool.get_children()
	# yes I know I could have just done this all in one loop if I removed the first panel but I
	# like having that there as a visual refrence
	range_offset = starting_panel + 2
	for child in child_array:
		set_panel(child,content_array[(child.get_index()+range_offset) % content_array.size()])
	organize(true)
	start_process()

func start_process():
	await get_tree().create_timer(.1).timeout
	start.emit(get_selected_record())

func _process(delta:float):
	if Input.is_action_just_pressed("ui_down"):
		shift_down()
		down.animate()
		pass
	elif Input.is_action_just_pressed("ui_up"):
		shift_up()
		up.animate()
		pass
	if Input.is_action_just_pressed("ui_accept"):
		select_button()
		select.animate()

func select_button():
	var selected_child:MenuPanel = menu_pool.get_child(selector_panel) 
	selected_child.select_panel()
	selected_option.emit(get_selected_record())

func get_selected_record() -> Song_Sample:
	return content_array[(range_offset + selector_panel)%content_array.size()]

func shift_down():
	#panel_offset_back()
	var child_end := menu_pool.get_child_count() - 1
	set_panel(get_hidden_panel(),get_previous_value())
	range_offset_back()
	menu_pool.move_child(menu_pool.get_child(child_end),0)
	organize(false,1)
	var selected_record = get_selected_record()
	option_changed.emit(get_selected_record(),-1)
	shift_sound.play()

func shift_up():
	#panel_offset_forward()
	var child_end := menu_pool.get_child_count() - 1
	set_panel(get_hidden_panel(),get_next_value())
	range_offset_forward()
	menu_pool.move_child(menu_pool.get_child(0),child_end)
	organize(false,-1)
	var selected_record = get_selected_record()
	option_changed.emit(get_selected_record(),1)
	shift_sound.play()

func set_panel(panel:MenuPanel,songdata:Song_Sample):
	panel.set_artist(songdata.SongArtist)
	panel.set_title(songdata.SongTitle)
	pass

func organize(instant:bool =false,direction:int=0):
	var child_array = menu_pool.get_children()
	var offset_Y = 0.0
	for child in child_array:
		var settween:Tween 
		if !instant:
			settween = get_tree().create_tween()
		var fade = MenuPanel.FADE_NONE
		#var thingy = abs(child.get_index()+ range_offset) % child_array.size()
		var offset_X = -height_value.position.x*abs(child.get_index() - selector_panel)
		var newpos:Vector2
		if child.faded:
			fade = MenuPanel.FADE_IN
			settween.tween_property(child,'position:y',offset_Y - (direction*seperation_value.position.y),.01)
		if child.get_index()>=panels:
			if instant:
				child.fade_instant(MenuPanel.FADE_OUT)
			else:
				fade = MenuPanel.FADE_OUT
			newpos = Vector2(hidden_position.position.x,child.position.y + (direction*seperation_value.position.y))
		else:
			newpos = Vector2(offset_X,offset_Y)
		if instant:
			child.position = newpos
		else:
			child.slide(newpos,slide_duration,fade,settween)
		offset_Y += seperation_value.position.y
	pass

#func panel_offset_back():
	#if panel_offset == 0:
		#panel_offset = menu_pool.get_child_count()-1
	#else:
		#panel_offset = abs(panel_offset-1) % menu_pool.get_child_count()
#func panel_offset_forward():
	#panel_offset = abs(panel_offset+1) % menu_pool.get_child_count()

func range_offset_back(): range_offset = get_previous_index()
func range_offset_forward(): range_offset = abs(range_offset+1) % content_array.size()
func range_offset_set(newval): range_offset = abs(newval) % content_array.size()
func get_previous_index()->int: 
	if range_offset == 0:
		return content_array.size()-1
	else:
		return abs(range_offset-1) % content_array.size()

func get_next_index()->int: return abs(panels+range_offset) % content_array.size()

func get_previous_value(): return content_array[get_previous_index()]
func get_next_value(): return content_array[get_next_index()]

func get_hidden_panel()->MenuPanel:
#	var thingy = abs(menu_pool.get_child_count()+panel_offset) % menu_pool.get_child_count()
#	print("hiddenpanel:"+str(thingy)+" Child count:"+str(menu_pool.get_child_count())+" range offset:"+str(range_offset))
	return menu_pool.get_child(menu_pool.get_child_count()-1)

func _on_selected_option(selected:Song_Sample):
	$SelectSound.play()
	pass # Replace with function body.

func _on_up_pressed():
	shift_up()
	pass # Replace with function body.

func _on_down_pressed():
	shift_down()
	pass # Replace with function body.

func _on_select_pressed():
	select_button()
	pass # Replace with function body.
