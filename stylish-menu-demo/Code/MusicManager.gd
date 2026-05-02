extends Node
@onready var sample_audio = %SampleAudio

func _on_cycling_menu_option_changed(sample:Song_Sample, direction):
	sample_audio.stop()
	sample_audio.stream = sample.Sample
	sample_audio.play()
	pass # Replace with function body.


func _on_cycling_menu_start(sample:Song_Sample):
	sample_audio.stream = sample.Sample
	sample_audio.play()
	pass # Replace with function body.


func _on_cycling_menu_selected_option(selected):
	sample_audio.stop()
	pass # Replace with function body.
