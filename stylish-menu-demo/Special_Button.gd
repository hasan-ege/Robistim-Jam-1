extends Button
@onready var button_logo = %ButtonLogo

func _on_pressed():
	animate()

func animate():
	QuickTweens.bounce(button_logo,"position:y",10)
