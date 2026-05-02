extends Node2D




func _on_cycling_menu_selected_option(selected:Song_Sample):
	OS.shell_open(selected.Url)
	pass 
